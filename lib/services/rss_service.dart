import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:sosigi/data/default_news_sources.dart';
import 'package:sosigi/core/enums/home_category.dart';
import 'package:sosigi/domain/models/article.dart';
import 'package:sosigi/domain/models/keyword_item.dart';
import 'package:sosigi/domain/models/news_source.dart';
import 'package:sosigi/services/app_logger.dart';
import 'package:webfeed_revised/webfeed_revised.dart';

class RssService {
  static const Duration _timeout = Duration(seconds: 6);
  static const int _maxItemsPerSource = 180;

  Future<List<Article>> fetchFromSources({
    required List<NewsSource> sources,
    required List<KeywordItem> keywords,
  }) async {
    final enabledSources = sources.where((source) => source.enabled).toList();
    if (enabledSources.isEmpty) {
      return [];
    }

    final futures = enabledSources.map(
      (source) => _fetchSource(
        source: source,
        keywords: keywords,
      ),
    );

    final results = await Future.wait(futures, eagerError: false);

    final deduped = <String, Article>{};

    for (final articles in results) {
      for (final article in articles) {
        final semanticKey = _semanticArticleKey(article);
        final existing = deduped[semanticKey];
        deduped[semanticKey] = existing == null
            ? article
            : _mergeArticles(existing, article);
      }
    }

    final merged = deduped.values.toList()
      ..sort((a, b) {
        final aDate = a.publishedAt ?? a.savedAt;
        final bDate = b.publishedAt ?? b.savedAt;
        return bDate.compareTo(aDate);
      });

    return merged;
  }

  Future<List<Article>> _fetchSource({
    required NewsSource source,
    required List<KeywordItem> keywords,
  }) async {
    try {
      final feedResults = await Future.wait(
        _feedUrlsForSource(source).map(
          (feedUrl) => _fetchFeed(
            source: source,
            feedUrl: feedUrl,
            keywords: keywords,
          ),
        ),
        eagerError: false,
      );

      final deduped = <String, Article>{};

      for (final articles in feedResults) {
        for (final article in articles) {
          final existing = deduped[article.id];
          deduped[article.id] = existing == null
              ? article
              : _mergeArticles(existing, article);
        }
      }

      return deduped.values.toList();
    } catch (e, st) {
      AppLogger.error('RssService', 'source exception: ${source.id}', e, st);
      return [];
    }
  }

  Future<List<Article>> _fetchFeed({
    required NewsSource source,
    required String feedUrl,
    required List<KeywordItem> keywords,
  }) async {
    try {
      final response = await http.get(Uri.parse(feedUrl)).timeout(_timeout);

      if (response.statusCode != 200) {
        return [];
      }

      final body = utf8.decode(response.bodyBytes);
      final feed = RssFeed.parse(body);
      final articles = <Article>[];

      for (final item in (feed.items ?? <RssItem>[]).take(_maxItemsPerSource)) {
        final title = _normalizeTitle(item.title ?? '');
        final rawLink = (item.link ?? '').trim();

        if (title.isEmpty || rawLink.isEmpty) continue;

        final cleanedLink = _normalizeLink(rawLink);
        final summary = _extractSummary(item);
        final publishedAt = _parsePublishedAt(item.pubDate);
        final isGoogleDerivedSource = _isGoogleDerivedSource(
          source: source,
          cleanedLink: cleanedLink,
        );

        final matchedKeywords = keywords
            .where(
              (keyword) => _containsKeyword(
                title,
                summary,
                keyword.name,
              ),
            )
            .map((keyword) => keyword.name)
            .toSet()
            .toList()
          ..sort();

        final semanticKey = _semanticKeyParts(
          title: title,
          publishedAt: publishedAt,
        );

        articles.add(
          Article(
            id: _stableArticleId(
              normalizedTitle: semanticKey.normalizedTitle,
              normalizedPublisher: semanticKey.normalizedPublisher,
              link: cleanedLink,
              publishedAt: publishedAt,
              isGoogleDerived: isGoogleDerivedSource,
            ),
            sourceId: source.id,
            title: title,
            sourceName: source.provider,
            link: cleanedLink,
            summary: summary,
            publishedAt: publishedAt,
            savedAt: DateTime.now(),
            category: _inferCategory(
              source.category,
              title,
              summary,
              source.provider,
            ),
            matchedKeywords: matchedKeywords,
            isKeywordMatched: matchedKeywords.isNotEmpty,
          ),
        );
      }

      return articles;
    } catch (e, st) {
      AppLogger.error('RssService', 'feed exception: ${source.id}', e, st);
      return [];
    }
  }

  List<String> _feedUrlsForSource(NewsSource source) {
    if (source.id == 'google') {
      return googleFeedUrls;
    }

    return [source.url];
  }

  String _extractSummary(RssItem item) {
    final raw = ((item.description ?? item.content?.value) ?? '').trim();
    if (raw.isEmpty) return '';
    return _stripHtml(raw);
  }

  DateTime? _parsePublishedAt(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      final normalized = value.trim();
      if (normalized.isEmpty) return null;

      final parsed = DateTime.tryParse(normalized);
      if (parsed != null) {
        return parsed.toLocal();
      }

      try {
        return HttpDate.parse(normalized).toLocal();
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  String _normalizeTitle(String input) {
    return input
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll('�', '')
        .trim();
  }

  String _normalizeLink(String input) {
    return input
        .trim()
        .replaceAll(RegExp(r'(\?|&)utm_[^&]+'), '')
        .replaceAll(RegExp(r'(\?|&)oc=5'), '')
        .replaceAll(RegExp(r'(\?|&)ref=[^&]+'), '')
        .replaceAll(RegExp(r'[?&]$'), '');
  }

  String _dedupeKey({
    required String title,
    required String link,
    required DateTime? publishedAt,
  }) {
    final normalizedTitle = title
        .toLowerCase()
        .replaceAll(RegExp(r'\[[^\]]*\]'), '')
        .replaceAll(RegExp(r'\([^)]*\)'), '')
        .replaceAll(RegExp(r'[^가-힣a-z0-9 ]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    final normalizedLink = _normalizeLink(link).toLowerCase();

    final isGoogleRedirect = normalizedLink.contains('news.google.com/');
    final publishedBucket = publishedAt == null
        ? ''
        : '${publishedAt.year}-${publishedAt.month}-${publishedAt.day}-${publishedAt.hour}';

    if (isGoogleRedirect) {
      return '$normalizedTitle|$publishedBucket';
    }

    return '$normalizedTitle|$normalizedLink';
  }

  String _stableArticleId({
    required String normalizedTitle,
    required String normalizedPublisher,
    required String link,
    required DateTime? publishedAt,
    required bool isGoogleDerived,
  }) {
    final normalizedLink = _normalizeLink(link).toLowerCase();
    if (isGoogleDerived) {
      return '$normalizedTitle|${_publishedDayBucket(publishedAt)}';
    }

    return _dedupeKey(
      title: normalizedTitle,
      link: normalizedLink,
      publishedAt: publishedAt,
    );
  }

  _SemanticKeyParts _semanticKeyParts({
    required String title,
    required DateTime? publishedAt,
  }) {
    final split = _splitTitleAndPublisher(title);
    return _SemanticKeyParts(
      normalizedTitle: _normalizeSemanticText(split.title),
      normalizedPublisher: _normalizeSemanticText(split.publisher),
      publishedBucket: _publishedBucket(publishedAt),
    );
  }

  String _semanticArticleKey(Article article) {
    final parts = _semanticKeyParts(
      title: article.title,
      publishedAt: article.publishedAt,
    );

    if (_isGoogleArticle(article)) {
      return '${parts.normalizedTitle}|${_publishedDayBucket(article.publishedAt)}';
    }

    return '${parts.normalizedTitle}|${parts.normalizedPublisher}|${parts.publishedBucket}';
  }

  bool _isGoogleDerivedSource({
    required NewsSource source,
    required String cleanedLink,
  }) {
    return source.id.startsWith('google') ||
        cleanedLink.toLowerCase().contains('news.google.com/');
  }

  bool _isGoogleArticle(Article article) {
    return article.sourceId.startsWith('google') ||
        article.link.toLowerCase().contains('news.google.com/');
  }

  _SplitTitle _splitTitleAndPublisher(String title) {
    final index = title.lastIndexOf(' - ');
    if (index <= 0 || index >= title.length - 3) {
      return _SplitTitle(title: title, publisher: '');
    }

    final headline = title.substring(0, index).trim();
    final publisher = title.substring(index + 3).trim();

    if (headline.isEmpty || publisher.isEmpty) {
      return _SplitTitle(title: title, publisher: '');
    }

    return _SplitTitle(title: headline, publisher: publisher);
  }

  String _normalizeSemanticText(String value) {
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
    return '${publishedAt.year.toString().padLeft(4, '0')}-'
        '${publishedAt.month.toString().padLeft(2, '0')}-'
        '${publishedAt.day.toString().padLeft(2, '0')}T'
        '${publishedAt.hour.toString().padLeft(2, '0')}:'
        '${publishedAt.minute.toString().padLeft(2, '0')}';
  }

  String _publishedDayBucket(DateTime? publishedAt) {
    if (publishedAt == null) return '';
    return '${publishedAt.year.toString().padLeft(4, '0')}-'
        '${publishedAt.month.toString().padLeft(2, '0')}-'
        '${publishedAt.day.toString().padLeft(2, '0')}';
  }

  Article _mergeArticles(Article primary, Article secondary) {
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
      publishedAt: latest.publishedAt ?? fallback.publishedAt,
      savedAt: latest.savedAt.isAfter(fallback.savedAt)
          ? latest.savedAt
          : fallback.savedAt,
      category: latest.category,
      matchedKeywords: {
        ...primary.matchedKeywords,
        ...secondary.matchedKeywords,
      }.toList()
        ..sort(),
      isKeywordMatched: primary.isKeywordMatched || secondary.isKeywordMatched,
    );
  }

  bool _containsKeyword(String title, String summary, String keyword) {
    final normalizedKeyword = keyword.trim().toLowerCase();
    if (normalizedKeyword.isEmpty) return false;

    final normalizedTitle = title.toLowerCase();
    final normalizedSummary = summary.toLowerCase();

    return normalizedTitle.contains(normalizedKeyword) ||
        normalizedSummary.contains(normalizedKeyword);
  }

  HomeCategory _inferCategory(
    HomeCategory sourceCategory,
    String title,
    String summary,
    String sourceProvider,
  ) {
    if (sourceCategory != HomeCategory.all &&
        sourceCategory != HomeCategory.uncategorized) {
      return sourceCategory;
    }

    final text = '$sourceProvider $title $summary'.toLowerCase();

    if (_hasAny(text, [
      '대통령',
      '국회',
      '정당',
      '선거',
      '정치',
      '외교',
      '장관',
      '총리',
      '여야',
      '청문회',
    ])) {
      return HomeCategory.politics;
    }

    if (_hasAny(text, [
      '증시',
      '환율',
      '경제',
      '금리',
      '주가',
      '코스피',
      '코스닥',
      '물가',
      '부동산',
      '수출',
      '수입',
      '실적',
      '기업',
    ])) {
      return HomeCategory.economy;
    }

    if (_hasAny(text, [
      '사회',
      '사건',
      '법원',
      '검찰',
      '경찰',
      '재판',
      '화재',
      '사고',
      '노조',
      '교육',
      '의료',
      '복지',
    ])) {
      return HomeCategory.society;
    }

    if (_hasAny(text, [
      '국제',
      '미국',
      '중국',
      '일본',
      '유럽',
      '중동',
      '러시아',
      '우크라이나',
      '트럼프',
      '바이든',
      '엔비디아',
      '해외',
    ])) {
      return HomeCategory.international;
    }

    if (_hasAny(text, [
      'ai',
      'it',
      '반도체',
      '애플',
      '삼성',
      '카카오',
      '네이버',
      '오픈ai',
      '챗gpt',
      '갤럭시',
      '아이폰',
      '테크',
      '플랫폼',
      '클라우드',
      '로봇',
      '전기차',
    ])) {
      return HomeCategory.it;
    }

    if (_hasAny(text, [
      '축구',
      '야구',
      '농구',
      '배구',
      '손흥민',
      '이강인',
      '스포츠',
      '올림픽',
      '메달',
      '프로야구',
      'mlb',
      'epl',
    ])) {
      return HomeCategory.sports;
    }

    if (_hasAny(text, [
      '연예',
      '배우',
      '가수',
      '드라마',
      '영화',
      '아이돌',
      '방송',
      '예능',
      '컴백',
      '공연',
      '콘서트',
    ])) {
      return HomeCategory.entertainment;
    }

    return HomeCategory.uncategorized;
  }

  bool _hasAny(String text, List<String> values) {
    return values.any((value) => text.contains(value.toLowerCase()));
  }

  String _stripHtml(String input) {
    return input
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll(RegExp(r'&nbsp;|&#160;'), ' ')
        .replaceAll(RegExp(r'&amp;'), '&')
        .replaceAll(RegExp(r'&quot;'), '"')
        .replaceAll(RegExp(r'&#39;'), "'")
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

class _SplitTitle {
  const _SplitTitle({
    required this.title,
    required this.publisher,
  });

  final String title;
  final String publisher;
}

class _SemanticKeyParts {
  const _SemanticKeyParts({
    required this.normalizedTitle,
    required this.normalizedPublisher,
    required this.publishedBucket,
  });

  final String normalizedTitle;
  final String normalizedPublisher;
  final String publishedBucket;
}
