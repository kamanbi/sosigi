import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:sosigi/domain/models/app_settings.dart';
import 'package:sosigi/domain/models/article.dart';
import 'package:sosigi/domain/models/keyword_item.dart';
import 'package:sosigi/services/app_logger.dart';
import 'package:sosigi/services/local_store_service.dart';
import 'package:sosigi/services/notification_service.dart';
import 'package:sosigi/services/rss_service.dart';

class NewsRefreshResult {
  const NewsRefreshResult({
    required this.allArticles,
    required this.lastSyncAt,
    required this.newArticleCount,
    required this.isBlockedByWifiPolicy,
    required this.isSkippedByCooldown,
    required this.statusMessage,
    required this.errorMessage,
  });

  final List<Article> allArticles;
  final DateTime? lastSyncAt;
  final int newArticleCount;
  final bool isBlockedByWifiPolicy;
  final bool isSkippedByCooldown;
  final String statusMessage;
  final String? errorMessage;
}

class NewsRefreshService {
  static const Duration _refreshLeaseStaleAfter = Duration(minutes: 2);
  static const String _refreshAlreadyRunningMessage = '이미 뉴스 업데이트가 진행 중입니다.';

  NewsRefreshService({
    LocalStoreService? store,
    RssService? rssService,
    NotificationService? notificationService,
    Connectivity? connectivity,
  })  : _store = store ?? LocalStoreService(),
        _rssService = rssService ?? RssService(),
        _notificationService = notificationService ?? NotificationService.instance,
        _connectivity = connectivity ?? Connectivity();

  final LocalStoreService _store;
  final RssService _rssService;
  final NotificationService _notificationService;
  final Connectivity _connectivity;

  Future<NewsRefreshResult> refresh({
    required bool force,
    required String refreshOwner,
  }) async {
    var hasRefreshLease = false;

    try {
      hasRefreshLease = await _store.tryAcquireRefreshLease(
        owner: refreshOwner,
        staleAfter: _refreshLeaseStaleAfter,
      );
      if (!hasRefreshLease) {
        final cachedArticles = await _safeLoadArticles();
        final lastSync = await _safeLoadLastSync();

        return NewsRefreshResult(
          allArticles: cachedArticles,
          lastSyncAt: lastSync,
          newArticleCount: 0,
          isBlockedByWifiPolicy: false,
          isSkippedByCooldown: false,
          statusMessage: _refreshAlreadyRunningMessage,
          errorMessage: null,
        );
      }

      final settings = await _store.loadSettings();
      final keywords = await _store.loadKeywords();
      final sources = await _store.loadSources();
      final currentArticles = await _store.loadArticles();
      final lastSync = await _store.loadLastSync();

      final enabledSources =
          sources.where((source) => source.enabled).toList(growable: false);
      if (enabledSources.isEmpty) {
        return NewsRefreshResult(
          allArticles: currentArticles,
          lastSyncAt: lastSync,
          newArticleCount: 0,
          isBlockedByWifiPolicy: false,
          isSkippedByCooldown: false,
          statusMessage: '활성화된 뉴스 소스가 없습니다.',
          errorMessage: null,
        );
      }

      if (!force &&
          lastSync != null &&
          currentArticles.isNotEmpty &&
          DateTime.now().difference(lastSync) < settings.syncInterval.duration) {
        return NewsRefreshResult(
          allArticles: currentArticles,
          lastSyncAt: lastSync,
          newArticleCount: 0,
          isBlockedByWifiPolicy: false,
          isSkippedByCooldown: true,
          statusMessage: '최근 업데이트 결과를 재사용합니다.',
          errorMessage: null,
        );
      }

      final connectivity = await _connectivity.checkConnectivity();
      final hasWifi = connectivity.contains(ConnectivityResult.wifi);

      if (settings.wifiOnly && !hasWifi) {
        return NewsRefreshResult(
          allArticles: currentArticles,
          lastSyncAt: lastSync,
          newArticleCount: 0,
          isBlockedByWifiPolicy: true,
          isSkippedByCooldown: false,
          statusMessage: 'Wi-Fi 사용 설정으로 업데이트가 제한되었습니다.',
          errorMessage: null,
        );
      }

      final fetched = await _rssService.fetchFromSources(
        sources: sources,
        keywords: keywords,
      );

      final retainedFetched = _applyRetention(
        fetched,
        settings.retentionOption,
      );

      final newArticles = _pickNewArticles(
        existing: currentArticles,
        fetched: retainedFetched,
      );

      final merged = _mergeFast(
        oldItems: currentArticles,
        newItems: retainedFetched,
      );

      final retained = _applyRetention(
        merged,
        settings.retentionOption,
      );

      final syncedAt = DateTime.now();

      await _store.saveArticles(retained);
      await _store.saveLastSync(syncedAt);
      await _pruneNotifiedKeys(retained);

      await _notifyForNewKeywordArticles(
        newArticles: newArticles,
        keywords: keywords,
      );

      return NewsRefreshResult(
        allArticles: retained,
        lastSyncAt: syncedAt,
        newArticleCount: newArticles.length,
        isBlockedByWifiPolicy: false,
        isSkippedByCooldown: false,
        statusMessage: newArticles.isEmpty
            ? '새 기사가 없습니다.'
            : '새 기사 ${newArticles.length}개를 불러왔습니다.',
        errorMessage: null,
      );
    } catch (e, st) {
      AppLogger.error('NewsRefreshService', 'refresh failed', e, st);
      final cachedArticles = await _safeLoadArticles();
      final lastSync = await _safeLoadLastSync();

      return NewsRefreshResult(
        allArticles: cachedArticles,
        lastSyncAt: lastSync,
        newArticleCount: 0,
        isBlockedByWifiPolicy: false,
        isSkippedByCooldown: false,
        statusMessage: '뉴스 업데이트 중 오류가 발생했습니다.',
        errorMessage: e.toString(),
      );
    } finally {
      if (hasRefreshLease) {
        try {
          await _store.releaseRefreshLease(owner: refreshOwner);
        } catch (e, st) {
          AppLogger.error(
            'NewsRefreshService',
            'releaseRefreshLease failed',
            e,
            st,
          );
        }
      }
    }
  }

  Future<List<Article>> _safeLoadArticles() async {
    try {
      return await _store.loadArticles();
    } catch (_) {
      return <Article>[];
    }
  }

  Future<DateTime?> _safeLoadLastSync() async {
    try {
      return await _store.loadLastSync();
    } catch (_) {
      return null;
    }
  }

  /// 보관 기간이 지난 기사의 알림 추적 키를 정리한다.
  /// 알림 키 형식: "keyword|articleSemanticKey"
  /// retained에 없는 articleSemanticKey를 가진 키는 더 이상 필요 없으므로 삭제한다.
  Future<void> _pruneNotifiedKeys(List<Article> retained) async {
    try {
      final allNotifiedKeys = await _store.loadNotifiedArticleKeys();
      if (allNotifiedKeys.isEmpty) return;

      final validArticleKeys = retained.map(_notificationFingerprint).toSet();

      final pruned = allNotifiedKeys.where((key) {
        final firstPipe = key.indexOf('|');
        if (firstPipe == -1) return false;
        return validArticleKeys.contains(key.substring(firstPipe + 1));
      }).toSet();

      if (pruned.length < allNotifiedKeys.length) {
        await _store.saveNotifiedArticleKeys(pruned);
      }
    } catch (e, st) {
      AppLogger.error('NewsRefreshService', 'pruneNotifiedKeys failed', e, st);
    }
  }

  Future<void> _notifyForNewKeywordArticles({
    required List<Article> newArticles,
    required List<KeywordItem> keywords,
  }) async {
    if (newArticles.isEmpty || keywords.isEmpty) return;

    final enabledKeywordsByLower = <String, String>{
      for (final keyword in keywords)
        if (keyword.notificationEnabled)
          keyword.name.trim().toLowerCase(): keyword.name,
    };

    if (enabledKeywordsByLower.isEmpty) return;

    // Hive 손상 시 notifiedKeys 로드 실패해도 알림 전송을 막지 않도록 try-catch.
    // 로드 실패 시 빈 Set을 사용해 이번 실행 내 중복만 방지한다.
    late final Set<String> notifiedKeys;
    try {
      notifiedKeys = await _store.loadNotifiedArticleKeys();
    } catch (e, st) {
      AppLogger.error(
        'NewsRefreshService',
        'loadNotifiedArticleKeys failed, using empty set',
        e,
        st,
      );
      notifiedKeys = {};
    }
    final grouped = <String, List<Article>>{};
    final nextNotifiedKeys = <String>{};

    for (final article in newArticles) {
      final matched = article.matchedKeywords
          .where(
            (keyword) => enabledKeywordsByLower.containsKey(
              keyword.trim().toLowerCase(),
            ),
          )
          .map(
            (keyword) => enabledKeywordsByLower[keyword.trim().toLowerCase()]!,
          )
          .toSet();

      for (final keyword in matched) {
        final notificationKey =
            '${keyword.trim().toLowerCase()}|${_notificationFingerprint(article)}';
        if (notifiedKeys.contains(notificationKey) ||
            !nextNotifiedKeys.add(notificationKey)) {
          AppLogger.info('NotificationDedup', 'skipped duplicate: $notificationKey');
          continue;
        }

        grouped.putIfAbsent(keyword, () => <Article>[]);
        grouped[keyword]!.add(article);
      }
    }

    for (final entry in grouped.entries) {
      try {
        await _notificationService.showKeywordSummary(
          keyword: entry.key,
          articles: entry.value,
        );
      } catch (e, st) {
        AppLogger.error('NewsRefreshService', 'notification error', e, st);
      }
    }

    if (nextNotifiedKeys.isNotEmpty) {
      await _store.saveNotifiedArticleKeys({
        ...notifiedKeys,
        ...nextNotifiedKeys,
      });
    }
  }

  List<Article> _pickNewArticles({
    required List<Article> existing,
    required List<Article> fetched,
  }) {
    final existingKeys = existing.map(_articleSemanticKey).toSet();
    final seenKeys = <String>{};

    return fetched.where((article) {
      final key = _articleSemanticKey(article);
      if (existingKeys.contains(key) || !seenKeys.add(key)) {
        return false;
      }
      return true;
    }).toList();
  }

  List<Article> _mergeFast({
    required List<Article> oldItems,
    required List<Article> newItems,
  }) {
    final map = <String, Article>{};

    for (final article in newItems) {
      final key = _articleSemanticKey(article);
      final existing = map[key];
      map[key] = existing == null ? article : _mergeArticle(existing, article);
    }

    for (final article in oldItems) {
      final key = _articleSemanticKey(article);
      final existing = map[key];
      map[key] = existing == null ? article : _mergeArticle(existing, article);
    }

    final result = map.values.toList()
      ..sort((a, b) {
        final aTime = a.publishedAt ?? a.savedAt;
        final bTime = b.publishedAt ?? b.savedAt;
        final timeCmp = bTime.compareTo(aTime);
        // 동일 시각이면 article ID로 tiebreak → 정렬 순서 안정화
        if (timeCmp != 0) return timeCmp;
        return a.id.compareTo(b.id);
      });

    return result;
  }

  String _articleSemanticKey(Article article) {
    final split = _splitTitleAndPublisher(article.title);
    final normalizedTitle = _normalizeSemanticTextSafe(split.$1);
    final normalizedPublisher = _normalizeSemanticTextSafe(split.$2);
    final publishedBucket = _publishedBucket(article.publishedAt);

    if (_isGoogleDerivedArticle(article)) {
      return '$normalizedTitle|${_publishedDayBucket(article.publishedAt)}';
    }

    return '$normalizedTitle|$normalizedPublisher|$publishedBucket';
  }

  /// 알림 중복 방지용 fingerprint.
  /// 소스 종류(직접/Google)에 무관하게 동일 뉴스 이벤트는 같은 값을 반환하도록
  /// normalizedTitle + dayBucket 만을 사용한다.
  /// link를 포함하면 같은 기사도 소스마다 fingerprint가 달라져 중복 알림이 발생한다.
  String _notificationFingerprint(Article article) {
    final split = _splitTitleAndPublisher(article.title);
    final normalizedTitle = _normalizeSemanticTextSafe(split.$1);
    return '$normalizedTitle|${_publishedDayBucket(article.publishedAt)}';
  }

  bool _isGoogleDerivedArticle(Article article) {
    final normalizedLink = article.link.trim().toLowerCase();
    // link가 news.google.com이면 무조건 Google 유래
    if (normalizedLink.contains('news.google.com/')) return true;
    // sourceId가 google_로 시작하더라도 직접 RSS(예: yna.co.kr)에서 온 기사는
    // 제목에 " - 언론사" 형식이 없으므로 Google 유래로 보지 않는다.
    return article.sourceId.startsWith('google') &&
        article.title.contains(' - ');
  }

  (String, String) _splitTitleAndPublisher(String title) {
    final index = title.lastIndexOf(' - ');
    if (index <= 0 || index >= title.length - 3) {
      return (title, '');
    }

    final headline = title.substring(0, index).trim();
    final publisher = title.substring(index + 3).trim();
    if (headline.isEmpty || publisher.isEmpty) {
      return (title, '');
    }

    return (headline, publisher);
  }

  String _normalizeSemanticTextSafe(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'\[[^\]]*\]'), ' ')
        .replaceAll(RegExp(r'\([^)]*\)'), ' ')
        .replaceAll(RegExp("[_/\\\\|.,!?:\"'`~\\-]+"), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _publishedBucket(DateTime? publishedAt) {
    if (publishedAt == null) return '';
    // 5분 단위로 버킷화: 같은 뉴스를 다른 소스가 1~4분 차이로 발행해도 동일 기사로 인식
    final bucketedMinute = (publishedAt.minute ~/ 5) * 5;
    return '${publishedAt.year.toString().padLeft(4, '0')}-'
        '${publishedAt.month.toString().padLeft(2, '0')}-'
        '${publishedAt.day.toString().padLeft(2, '0')}T'
        '${publishedAt.hour.toString().padLeft(2, '0')}:'
        '${bucketedMinute.toString().padLeft(2, '0')}';
  }

  DateTime? _earlierPublishedAt(DateTime? a, DateTime? b) {
    if (a == null) return b;
    if (b == null) return a;
    return a.isBefore(b) ? a : b;
  }

  String _publishedDayBucket(DateTime? publishedAt) {
    if (publishedAt == null) return '';
    return '${publishedAt.year.toString().padLeft(4, '0')}-'
        '${publishedAt.month.toString().padLeft(2, '0')}-'
        '${publishedAt.day.toString().padLeft(2, '0')}';
  }

  Article _mergeArticle(Article primary, Article secondary) {
    final primaryTime = primary.publishedAt ?? primary.savedAt;
    final secondaryTime = secondary.publishedAt ?? secondary.savedAt;
    final latest = secondaryTime.isAfter(primaryTime) ? secondary : primary;
    final fallback = identical(latest, primary) ? secondary : primary;

    return Article(
      id: latest.id,
      sourceId: latest.sourceId,
      title: latest.title,
      sourceName: latest.sourceName,
      link: latest.link.isNotEmpty ? latest.link : fallback.link,
      summary: latest.summary.length >= fallback.summary.length
          ? latest.summary
          : fallback.summary,
      publishedAt: _earlierPublishedAt(primary.publishedAt, secondary.publishedAt),
      // 최초 저장 시각을 보존한다. max를 쓰면 매 fetch마다 savedAt이 갱신되어
      // publishedAt이 없는 기사들의 정렬 위치가 계속 바뀐다.
      savedAt: primary.savedAt.isBefore(secondary.savedAt)
          ? primary.savedAt
          : secondary.savedAt,
      category: latest.category,
      matchedKeywords: {
        ...primary.matchedKeywords,
        ...secondary.matchedKeywords,
      }.toList()
        ..sort(),
      isKeywordMatched: primary.isKeywordMatched || secondary.isKeywordMatched,
    );
  }

  List<Article> _applyRetention(
    List<Article> items,
    RetentionOption option,
  ) {
    final duration = option.duration;
    final now = DateTime.now();

    return items.where((article) {
      final baseTime = article.publishedAt ?? article.savedAt;
      return now.difference(baseTime) <= duration;
    }).toList();
  }
}
