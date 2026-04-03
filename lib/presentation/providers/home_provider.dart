import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sosigi/core/enums/home_category.dart';
import 'package:sosigi/domain/models/app_settings.dart';
import 'package:sosigi/domain/models/article.dart';
import 'package:sosigi/domain/models/keyword_item.dart';
import 'package:sosigi/domain/models/news_source.dart';
import 'package:sosigi/presentation/providers/app_settings_provider.dart';
import 'package:sosigi/presentation/providers/keyword_provider.dart';
import 'package:sosigi/presentation/providers/news_source_provider.dart';
import 'package:sosigi/services/app_logger.dart';
import 'package:sosigi/services/background_sync_scheduler.dart';
import 'package:sosigi/services/news_refresh_service.dart';

const _unset = Object();

class HomeState {
  const HomeState({
    required this.isLoading,
    required this.selectedCategory,
    required this.selectedKeyword,
    required this.allArticles,
    required this.visibleArticles,
    required this.lastSyncAt,
    required this.searchQuery,
    required this.statusMessage,
    required this.userMessage,
    required this.errorMessage,
    required this.isBlockedByWifiPolicy,
    required this.lastRefreshNewCount,
  });

  final bool isLoading;
  final HomeCategory selectedCategory;
  final String? selectedKeyword;
  final List<Article> allArticles;
  final List<Article> visibleArticles;
  final DateTime? lastSyncAt;
  final String searchQuery;
  final String? statusMessage;
  final String? userMessage;
  final String? errorMessage;
  final bool isBlockedByWifiPolicy;
  final int lastRefreshNewCount;

  factory HomeState.initial() {
    return const HomeState(
      isLoading: false,
      selectedCategory: HomeCategory.all,
      selectedKeyword: null,
      allArticles: [],
      visibleArticles: [],
      lastSyncAt: null,
      searchQuery: '',
      statusMessage: null,
      userMessage: null,
      errorMessage: null,
      isBlockedByWifiPolicy: false,
      lastRefreshNewCount: 0,
    );
  }

  HomeState copyWith({
    bool? isLoading,
    HomeCategory? selectedCategory,
    Object? selectedKeyword = _unset,
    List<Article>? allArticles,
    List<Article>? visibleArticles,
    Object? lastSyncAt = _unset,
    String? searchQuery,
    Object? statusMessage = _unset,
    Object? userMessage = _unset,
    Object? errorMessage = _unset,
    bool? isBlockedByWifiPolicy,
    int? lastRefreshNewCount,
  }) {
    return HomeState(
      isLoading: isLoading ?? this.isLoading,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      selectedKeyword: identical(selectedKeyword, _unset)
          ? this.selectedKeyword
          : selectedKeyword as String?,
      allArticles: allArticles ?? this.allArticles,
      visibleArticles: visibleArticles ?? this.visibleArticles,
      lastSyncAt: identical(lastSyncAt, _unset)
          ? this.lastSyncAt
          : lastSyncAt as DateTime?,
      searchQuery: searchQuery ?? this.searchQuery,
      statusMessage: identical(statusMessage, _unset)
          ? this.statusMessage
          : statusMessage as String?,
      userMessage: identical(userMessage, _unset)
          ? this.userMessage
          : userMessage as String?,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      isBlockedByWifiPolicy:
          isBlockedByWifiPolicy ?? this.isBlockedByWifiPolicy,
      lastRefreshNewCount: lastRefreshNewCount ?? this.lastRefreshNewCount,
    );
  }
}

final newsRefreshServiceProvider = Provider<NewsRefreshService>((ref) {
  return NewsRefreshService(
    store: ref.read(localStoreProvider),
  );
});

final homeProvider = StateNotifierProvider<HomeNotifier, HomeState>((ref) {
  final notifier = HomeNotifier(ref);

  ref.listen<AppSettings>(appSettingsProvider, (previous, next) {
    if (previous == null) return;
    notifier.handleSettingsChanged(previous, next);
  });

  ref.listen<List<KeywordItem>>(keywordProvider, (previous, next) {
    if (previous == null) return;
    notifier.handleKeywordsChanged(previous, next);
  });

  ref.listen<List<NewsSource>>(newsSourceProvider, (previous, next) {
    if (previous == null) return;
    notifier.handleSourcesChanged(previous, next);
  });

  unawaited(notifier.initialize());
  return notifier;
});

class HomeNotifier extends StateNotifier<HomeState> {
  HomeNotifier(this.ref) : super(HomeState.initial());

  final Ref ref;

  bool _refreshing = false;
  bool _initialized = false;
  bool _initializing = false;
  Timer? _autoRefreshTimer;

  Future<void> initialize() async {
    if (_initialized || _initializing) return;
    _initializing = true;

    try {
      await _ensureDependenciesLoaded();

      final store = ref.read(localStoreProvider);
      final cachedArticles = await store.loadArticles();
      final lastSync = await store.loadLastSync();
      final settings = ref.read(appSettingsProvider);

      final retained = _applyRetention(
        cachedArticles,
        settings.retentionOption,
      );

      state = state.copyWith(
        allArticles: retained,
        lastSyncAt: lastSync,
      );

      _recomputeVisible(keywords: ref.read(keywordProvider));
      _configureAutoRefresh(settings);
      _initialized = true;

    } catch (e, st) {
      AppLogger.error('HomeNotifier', 'initialize failed', e, st);
      state = state.copyWith(
        errorMessage: '앱 초기화에 실패했습니다.',
        statusMessage: '초기화 중 문제가 발생했습니다.',
      );
    } finally {
      _initializing = false;
    }

    if (_initialized) {
      await refresh(force: false);
    }
  }

  Future<void> _ensureDependenciesLoaded() async {
    await ref.read(appSettingsProvider.notifier).load();
    await ref.read(keywordProvider.notifier).load();
    await ref.read(newsSourceProvider.notifier).load();

  }

  void handleSettingsChanged(AppSettings previous, AppSettings next) {
    if (!_initialized) return;

    _configureAutoRefresh(next);

    if (previous.syncInterval != next.syncInterval ||
        previous.wifiOnly != next.wifiOnly) {
      unawaited(BackgroundSyncScheduler.instance.schedule(next));
    }

    if (previous.wifiOnly != next.wifiOnly && !next.wifiOnly) {
      unawaited(refresh(force: true));
    }
  }

  void handleKeywordsChanged(
    List<KeywordItem> previous,
    List<KeywordItem> next,
  ) {
    if (!_initialized) return;
    _recomputeVisible(keywords: next);
  }

  void handleSourcesChanged(
    List<NewsSource> previous,
    List<NewsSource> next,
  ) {
    if (!_initialized) return;

    _recomputeVisible(keywords: ref.read(keywordProvider));

    final previousEnabled = previous
        .where((source) => source.enabled)
        .map((source) => source.id)
        .toSet();
    final nextEnabled = next
        .where((source) => source.enabled)
        .map((source) => source.id)
        .toSet();

    if (previousEnabled.length != nextEnabled.length ||
        !previousEnabled.containsAll(nextEnabled)) {
      unawaited(refresh(force: true));
    }
  }

  void setSearchQuery(String value) {
    state = state.copyWith(searchQuery: value);
    _recomputeVisible(keywords: ref.read(keywordProvider));
  }

  void clearSearchQuery() {
    state = state.copyWith(searchQuery: '');
    _recomputeVisible(keywords: ref.read(keywordProvider));
  }

  void clearUserMessage() {
    state = state.copyWith(userMessage: null);
  }

  void _configureAutoRefresh(AppSettings settings) {
    _autoRefreshTimer?.cancel();

    final duration = settings.syncInterval.duration;
    _autoRefreshTimer = Timer.periodic(duration, (_) async {
      await refresh(force: false, userInitiated: false);
    });
  }

  Future<void> syncFromStore() async {
    if (!_initialized) return;

    final store = ref.read(localStoreProvider);
    final settings = ref.read(appSettingsProvider);
    final keywords = ref.read(keywordProvider);
    final storedArticles = await store.loadArticles();
    final storedLastSync = await store.loadLastSync();
    final retainedArticles = _applyRetention(
      storedArticles,
      settings.retentionOption,
    );

    state = state.copyWith(
      allArticles: retainedArticles,
      lastSyncAt: storedLastSync,
    );
    _recomputeVisible(keywords: keywords);
  }

  Future<void> refresh({
    required bool force,
    bool userInitiated = false,
  }) async {
    if (!_initialized) {
      await initialize();
      if (!_initialized) return;
    }

    if (_refreshing) {
      return;
    }

    _refreshing = true;
    state = state.copyWith(
      isLoading: true,
      statusMessage: null,
      userMessage: null,
      errorMessage: null,
      isBlockedByWifiPolicy: false,
    );

    try {
      final refreshResult = await ref.read(newsRefreshServiceProvider).refresh(
            force: force,
            refreshOwner: userInitiated
                ? 'foreground_manual'
                : 'foreground_auto',
          );

      state = state.copyWith(
        isLoading: false,
        allArticles: refreshResult.allArticles,
        lastSyncAt: refreshResult.lastSyncAt,
        statusMessage: refreshResult.statusMessage,
        userMessage: userInitiated ? refreshResult.statusMessage : null,
        errorMessage: refreshResult.errorMessage,
        isBlockedByWifiPolicy: refreshResult.isBlockedByWifiPolicy,
        lastRefreshNewCount: refreshResult.newArticleCount,
      );

      _recomputeVisible(keywords: ref.read(keywordProvider));
    } catch (e, st) {
      AppLogger.error('HomeNotifier', 'refresh failed', e, st);
      state = state.copyWith(
        isLoading: false,
        statusMessage: '뉴스 업데이트에 실패했습니다.',
        userMessage: userInitiated ? '뉴스 업데이트에 실패했습니다.' : null,
        errorMessage: e.toString(),
        isBlockedByWifiPolicy: false,
        lastRefreshNewCount: 0,
      );
    } finally {
      _refreshing = false;
    }
  }

  void selectCategory(HomeCategory category) {
    state = state.copyWith(
      selectedCategory: category,
      selectedKeyword:
          category == HomeCategory.keyword ? state.selectedKeyword : null,
    );

    _recomputeVisible(keywords: ref.read(keywordProvider));
  }

  void selectKeyword(String keyword) {
    state = state.copyWith(
      selectedCategory: HomeCategory.keyword,
      selectedKeyword: keyword,
    );

    _recomputeVisible(keywords: ref.read(keywordProvider));
  }

  void nextCategory() {
    const categories = HomeCategory.values;
    final currentIndex = categories.indexOf(state.selectedCategory);

    if (currentIndex < categories.length - 1) {
      selectCategory(categories[currentIndex + 1]);
    }
  }

  void previousCategory() {
    const categories = HomeCategory.values;
    final currentIndex = categories.indexOf(state.selectedCategory);

    if (currentIndex > 0) {
      selectCategory(categories[currentIndex - 1]);
    }
  }

  void _recomputeVisible({
    required List<KeywordItem> keywords,
  }) {
    final normalizedState = _normalizeSelectionState(
      current: state,
      keywords: keywords,
    );

    final visible = _computeVisibleArticles(
      allArticles: normalizedState.allArticles,
      selectedCategory: normalizedState.selectedCategory,
      selectedKeyword: normalizedState.selectedKeyword,
      enabledSources: ref.read(newsSourceProvider),
      searchQuery: normalizedState.searchQuery,
    );

    state = normalizedState.copyWith(visibleArticles: visible);
  }

  HomeState _normalizeSelectionState({
    required HomeState current,
    required List<KeywordItem> keywords,
  }) {
    if (current.selectedCategory != HomeCategory.keyword) {
      return current.copyWith(selectedKeyword: null);
    }

    if (keywords.isEmpty) {
      return current.copyWith(selectedKeyword: null);
    }

    final selectedKeyword = current.selectedKeyword;
    final exists = selectedKeyword != null &&
        keywords.any(
          (keyword) => keyword.name.toLowerCase() == selectedKeyword.toLowerCase(),
        );

    if (exists) {
      return current;
    }

    return current.copyWith(selectedKeyword: keywords.first.name);
  }

  List<Article> _computeVisibleArticles({
    required List<Article> allArticles,
    required HomeCategory selectedCategory,
    required String? selectedKeyword,
    required List<NewsSource> enabledSources,
    required String searchQuery,
  }) {
    var result = allArticles
        .where(
          (article) => enabledSources.any(
            (source) => source.enabled && _matchesSource(article, source),
          ),
        )
        .toList();

    if (selectedCategory == HomeCategory.keyword) {
      final keyword = selectedKeyword?.trim();

      if (keyword == null || keyword.isEmpty) {
        result = [];
      } else {
        result = result
            .where(
              (article) => article.matchedKeywords.any(
                (matched) => matched.toLowerCase() == keyword.toLowerCase(),
              ),
            )
            .toList();
      }
    } else if (selectedCategory != HomeCategory.all) {
      result = result
          .where((article) => article.category == selectedCategory)
          .toList();
    }

    final normalizedSearch = searchQuery.trim().toLowerCase();
    if (normalizedSearch.isNotEmpty) {
      result = result.where((article) {
        final haystack =
            '${article.title} ${article.summary} ${article.sourceName}'
                .toLowerCase();
        return haystack.contains(normalizedSearch);
      }).toList();
    }

    return result;
  }

  bool _matchesSource(Article article, NewsSource source) {
    if (source.id == 'google') {
      return article.sourceId.startsWith('google') ||
          article.sourceName.toLowerCase().contains('google');
    }

    return article.sourceId == source.id || article.sourceName == source.provider;
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

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }
}
