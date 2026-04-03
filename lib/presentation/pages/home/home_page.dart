import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sosigi/app/router.dart';
import 'package:sosigi/app/theme/app_colors.dart';
import 'package:sosigi/app/theme/app_text_styles.dart';
import 'package:sosigi/core/ads/article_open_ad_counter_service.dart';
import 'package:sosigi/core/ads/exit_interstitial_ad_service.dart';
import 'package:sosigi/core/enums/home_category.dart';
import 'package:sosigi/domain/models/article.dart';
import 'package:sosigi/presentation/providers/app_settings_provider.dart';
import 'package:sosigi/presentation/providers/article_state_provider.dart';
import 'package:sosigi/presentation/providers/home_provider.dart';
import 'package:sosigi/presentation/providers/keyword_provider.dart';
import 'package:sosigi/presentation/providers/news_source_provider.dart';
import 'package:sosigi/presentation/widgets/common/bottom_banner_ad.dart';
import 'package:sosigi/presentation/widgets/common/inline_banner_ad.dart';
import 'package:sosigi/presentation/widgets/common/network_block_card.dart';
import 'package:sosigi/presentation/widgets/common/premium_card.dart';
import 'package:sosigi/presentation/widgets/common/sosigi_scaffold.dart';
import 'package:sosigi/presentation/widgets/home/category_selector_card.dart';
import 'package:sosigi/presentation/widgets/home/news_card.dart';
import 'package:sosigi/services/notification_service.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with WidgetsBindingObserver {
  static const String _appIconAsset =
      'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png';
  static const Duration _manualRefreshLockDuration = Duration(seconds: 5);
  bool _isExiting = false;
  bool _isManualRefreshLocked = false;
  int _transitionDirection = 1;
  List<ConnectivityResult> _connectivityResults = const <ConnectivityResult>[];
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  final TextEditingController _searchController = TextEditingController();
  ProviderSubscription<HomeState>? _homeStateSubscription;
  Timer? _manualRefreshLockTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    unawaited(ref.read(articleStateProvider.notifier).load());

    _homeStateSubscription = ref.listenManual<HomeState>(
      homeProvider,
      (previous, next) {
        final previousMessage = previous?.userMessage;
        final nextMessage = next.userMessage;

        if (nextMessage == null || nextMessage.isEmpty) return;
        if (previousMessage == nextMessage) return;
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(nextMessage)),
        );

        ref.read(homeProvider.notifier).clearUserMessage();
      },
    );

    NotificationService.instance.selectedKeywordFromNotification
        .addListener(_handleNotificationKeyword);

    Connectivity().checkConnectivity().then((results) {
      if (!mounted) return;
      setState(() {
        _connectivityResults = results;
      });
    });

    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((results) {
      if (!mounted) return;
      setState(() {
        _connectivityResults = results;
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleNotificationKeyword();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _homeStateSubscription?.close();
    _searchController.dispose();
    _connectivitySubscription?.cancel();
    _manualRefreshLockTimer?.cancel();
    NotificationService.instance.selectedKeywordFromNotification
        .removeListener(_handleNotificationKeyword);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    unawaited(ref.read(homeProvider.notifier).syncFromStore());
  }

  Future<void> _handleNotificationKeyword() async {
    final keyword =
        NotificationService.instance.selectedKeywordFromNotification.value;
    if (keyword == null || keyword.trim().isEmpty) return;

    final trimmed = keyword.trim();
    final keywords = ref.read(keywordProvider);

    final exists = keywords.any(
      (item) => item.name.toLowerCase() == trimmed.toLowerCase(),
    );

    if (!exists) {
      await ref.read(keywordProvider.notifier).addKeyword(trimmed);
    }

    _selectCategory(HomeCategory.keyword);
    ref.read(homeProvider.notifier).selectKeyword(trimmed);

    NotificationService.instance.consumeSelectedKeyword();
  }

  Future<bool> _showExitDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            '앱을 종료할까요?',
            style: AppTextStyles.sectionTitle.copyWith(fontSize: 18),
          ),
          content: Text(
            '확인 버튼을 누르면 광고가 표시된 뒤 앱이 종료됩니다.',
            style: AppTextStyles.sectionBody.copyWith(fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                '취소',
                style: AppTextStyles.button.copyWith(
                  color: AppColors.secondaryText,
                  fontSize: 14,
                ),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.navy,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                '확인',
                style: AppTextStyles.button.copyWith(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Future<void> _exitWithAd() async {
    if (_isExiting) return;
    _isExiting = true;

    await ExitInterstitialAdService.instance.showIfReady();
    await Future<void>.delayed(const Duration(milliseconds: 250));

    if (!mounted) return;
    await SystemNavigator.pop();
  }

  Future<void> _handleBackPressed() async {
    final confirmed = await _showExitDialog();
    if (!confirmed) return;
    await _exitWithAd();
  }

  int _categoryIndex(HomeCategory category) {
    return HomeCategory.values.indexOf(category);
  }

  void _selectCategory(HomeCategory category) {
    final current = ref.read(homeProvider).selectedCategory;
    final currentIndex = _categoryIndex(current);
    final nextIndex = _categoryIndex(category);

    if (currentIndex != nextIndex) {
      setState(() {
        _transitionDirection = nextIndex > currentIndex ? 1 : -1;
      });
    }

    ref.read(homeProvider.notifier).selectCategory(category);
  }

  void _nextCategory() {
    setState(() {
      _transitionDirection = 1;
    });
    ref.read(homeProvider.notifier).nextCategory();
  }

  void _previousCategory() {
    setState(() {
      _transitionDirection = -1;
    });
    ref.read(homeProvider.notifier).previousCategory();
  }

  Future<void> _handleManualRefresh() async {
    final homeState = ref.read(homeProvider);
    if (_isManualRefreshLocked || homeState.isLoading) {
      return;
    }

    setState(() {
      _isManualRefreshLocked = true;
    });

    try {
      await ref.read(homeProvider.notifier).refresh(
            force: true,
            userInitiated: true,
          );
    } finally {
      _manualRefreshLockTimer?.cancel();
      _manualRefreshLockTimer = Timer(_manualRefreshLockDuration, () {
        if (!mounted) return;
        setState(() {
          _isManualRefreshLocked = false;
        });
      });
    }
  }

  Widget _buildToolbarButton({
    required VoidCallback? onPressed,
    required IconData icon,
    String? label,
  }) {
    final isEnabled = onPressed != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          height: 54,
          width: label == null ? 54 : null,
          padding: EdgeInsets.symmetric(horizontal: label == null ? 0 : 14),
          decoration: BoxDecoration(
            color: isEnabled ? AppColors.surface : AppColors.inactive,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 22,
                color: isEnabled ? AppColors.navy : AppColors.secondaryText,
              ),
              if (label != null) ...[
                const SizedBox(width: 8),
                Text(
                  label,
                  style: AppTextStyles.sectionTitle.copyWith(
                    fontSize: 13,
                    color: isEnabled
                        ? AppColors.primaryText
                        : AppColors.secondaryText,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildArticleWidgets(
    List<Article> articles,
    ArticleUserState articleState,
  ) {
    final widgets = <Widget>[];

    for (int i = 0; i < articles.length; i++) {
      final article = articles[i];

      widgets.add(
        NewsCard(
          article: article,
          isRead: articleState.readIds.contains(article.id),
          isBookmarked: articleState.bookmarkedIds.contains(article.id),
          onBeforeOpen: () async {
            await ArticleOpenAdCounterService.instance
                .recordOpenAndMaybeShowInterstitial();
          },
          onOpened: () {
            ref.read(articleStateProvider.notifier).markRead(article.id);
          },
          onToggleBookmark: () {
            ref.read(articleStateProvider.notifier).toggleBookmark(article.id);
          },
        ),
      );

      if ((i + 1) % 10 == 0) {
        widgets.add(const InlineBannerAd());
      }
    }

    return widgets;
  }

  Widget _buildEmptyState({
    required BuildContext context,
    required String title,
    required String body,
  }) {
    return ListView(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.45,
          child: PremiumCard(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.largeEmptyTitle,
                ),
                const SizedBox(height: 10),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.largeEmptyBody,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homeProvider);
    final homeNotifier = ref.read(homeProvider.notifier);
    final appSettings = ref.watch(appSettingsProvider);
    final keywordItems = ref.watch(keywordProvider);
    final keywordList = keywordItems.map((item) => item.name).toList();
    final articleState = ref.watch(articleStateProvider);
    final sources = ref.watch(newsSourceProvider);
    final enabledSourceCount = sources.where((e) => e.enabled).length;

    if (_searchController.text != homeState.searchQuery) {
      _searchController.value = _searchController.value.copyWith(
        text: homeState.searchQuery,
        selection: TextSelection.collapsed(
          offset: homeState.searchQuery.length,
        ),
      );
    }

    final isKeywordMode = homeState.selectedCategory == HomeCategory.keyword;
    final isManualRefreshEnabled =
        !_isManualRefreshLocked && !homeState.isLoading;
    final isWifi = _connectivityResults.contains(ConnectivityResult.wifi);
    final transitionKey = [
      homeState.selectedCategory.name,
      homeState.selectedKeyword ?? '',
      homeState.searchQuery,
    ].join('|');

    final shouldBlockByWifiPolicy =
        appSettings.wifiOnly &&
        !isWifi &&
        homeState.visibleArticles.isEmpty &&
        homeState.isBlockedByWifiPolicy &&
        !homeState.isLoading;

    var syncText = '동기화 기록 없음';
    if (homeState.lastSyncAt != null) {
      syncText =
          '최근 업데이트 ${DateFormat('MM.dd HH:mm').format(homeState.lastSyncAt!)}';
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleBackPressed();
      },
      child: SosigiScaffold(
        bottomNavigationBar: const BottomBannerAd(),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 46,
                    height: 46,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(13),
                      child: Image.asset(
                        _appIconAsset,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SOSIGI',
                          style: AppTextStyles.brand.copyWith(
                            fontSize: 22,
                            letterSpacing: 2.2,
                            color: AppColors.navy,
                          ),
                        ),
                        Text(
                          'EXECUTIVE NEWS',
                          style: AppTextStyles.caption.copyWith(
                            fontSize: 10,
                            letterSpacing: 1.6,
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildToolbarButton(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRouter.settings);
                    },
                    icon: Icons.tune_rounded,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: CategorySelectorCard(
                          selectedCategory: homeState.selectedCategory,
                          onSelected: _selectCategory,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildToolbarButton(
                        onPressed:
                            isManualRefreshEnabled ? _handleManualRefresh : null,
                        icon: Icons.refresh_rounded,
                        label: '업데이트',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.sync_rounded,
                          size: 18,
                          color: AppColors.secondaryText,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            syncText,
                            style: AppTextStyles.caption,
                          ),
                        ),
                        Text(
                          '소스 $enabledSourceCount개',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _searchController,
                    onChanged: homeNotifier.setSearchQuery,
                    decoration: InputDecoration(
                      hintText: '기사 검색',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: homeState.searchQuery.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _searchController.clear();
                                homeNotifier.clearSearchQuery();
                              },
                              icon: const Icon(Icons.close_rounded),
                            ),
                      filled: true,
                      fillColor: AppColors.surface,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.cardBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.navy),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (homeState.isLoading) const LinearProgressIndicator(minHeight: 2),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onHorizontalDragEnd: (details) {
                  final velocity = details.primaryVelocity ?? 0;
                  if (velocity < -200) {
                    _nextCategory();
                  } else if (velocity > 200) {
                    _previousCategory();
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 0),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 520),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    layoutBuilder: (currentChild, previousChildren) {
                      return ClipRect(
                        child: Stack(
                          fit: StackFit.expand,
                          children: <Widget>[
                            ...previousChildren,
                            if (currentChild != null) currentChild,
                          ],
                        ),
                      );
                    },
                    transitionBuilder: (child, animation) {
                      final currentKey = ValueKey<String>(transitionKey);
                      final isIncoming = child.key == currentKey;
                      final incomingAnimation = CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      );
                      final outgoingAnimation = CurvedAnimation(
                        parent: ReverseAnimation(animation),
                        curve: Curves.easeInOutCubic,
                      );

                      final incomingOffset = Tween<Offset>(
                        begin: Offset(_transitionDirection * 0.3, 0),
                        end: Offset.zero,
                      ).animate(incomingAnimation);

                      final outgoingOffset = Tween<Offset>(
                        begin: Offset.zero,
                        end: Offset(_transitionDirection * -0.3, 0),
                      ).animate(outgoingAnimation);

                      final incomingScale = Tween<double>(
                        begin: 0.96,
                        end: 1,
                      ).animate(incomingAnimation);

                      final outgoingScale = Tween<double>(
                        begin: 1,
                        end: 0.94,
                      ).animate(outgoingAnimation);

                      return FadeTransition(
                        opacity: isIncoming ? incomingAnimation : outgoingAnimation,
                        child: SlideTransition(
                          position: isIncoming ? incomingOffset : outgoingOffset,
                          child: ScaleTransition(
                            scale: isIncoming ? incomingScale : outgoingScale,
                            child: child,
                          ),
                        ),
                      );
                    },
                    child: Builder(
                      key: ValueKey<String>(transitionKey),
                      builder: (context) {
                        if (shouldBlockByWifiPolicy) {
                          return const NetworkBlockCard();
                        }

                        if (isKeywordMode) {
                          return Column(
                            children: [
                              if (keywordList.isNotEmpty)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                decoration: BoxDecoration(
                                  color: AppColors.accentSoft,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppColors.cardBorder,
                                    ),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: keywordList.contains(
                                              homeState.selectedKeyword)
                                          ? homeState.selectedKeyword
                                          : keywordList.first,
                                      isExpanded: true,
                                      borderRadius: BorderRadius.circular(16),
                                      dropdownColor: AppColors.accentSoft,
                                      style: AppTextStyles.sectionTitle.copyWith(
                                        fontSize: 14,
                                        color: AppColors.primaryText,
                                      ),
                                      items: keywordList.map((keyword) {
                                        return DropdownMenuItem<String>(
                                          value: keyword,
                                          child: Text(
                                            keyword,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        if (value == null) return;
                                        homeNotifier.selectKeyword(value);
                                      },
                                    ),
                                  ),
                                ),
                              if (keywordList.isNotEmpty)
                                const SizedBox(height: 8),
                              Expanded(
                                child: RefreshIndicator(
                                  onRefresh: _handleManualRefresh,
                                  child: homeState.visibleArticles.isEmpty
                                      ? _buildEmptyState(
                                          context: context,
                                          title: keywordList.isEmpty
                                              ? '등록된 키워드가 없습니다.'
                                              : homeState.searchQuery.isNotEmpty
                                                  ? '검색 결과가 없습니다.'
                                                  : '"${homeState.selectedKeyword ?? ''}" 키워드 기사 없음',
                                          body: keywordList.isEmpty
                                              ? '설정에서 키워드를 등록한 뒤 다시 확인해 주세요.'
                                              : homeState.searchQuery.isNotEmpty
                                                  ? '검색어를 바꾸거나 초기화해 주세요.'
                                                  : '잠시 뒤 다시 확인하거나 다른 키워드를 선택해 주세요.',
                                        )
                                      : ListView(
                                          children: _buildArticleWidgets(
                                            homeState.visibleArticles,
                                            articleState,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          );
                        }

                        return RefreshIndicator(
                          onRefresh: _handleManualRefresh,
                          child: homeState.visibleArticles.isEmpty
                              ? _buildEmptyState(
                                  context: context,
                                  title: enabledSourceCount == 0
                                      ? '활성화된 뉴스 소스가 없습니다.'
                                      : homeState.errorMessage != null
                                          ? '뉴스 업데이트 실패'
                                          : homeState.searchQuery.isNotEmpty
                                              ? '검색 결과가 없습니다.'
                                              : '표시할 뉴스가 없습니다.',
                                  body: enabledSourceCount == 0
                                      ? '설정에서 뉴스 소스를 하나 이상 켜 주세요.'
                                      : homeState.errorMessage != null
                                          ? '잠시 뒤 다시 시도하거나 네트워크 상태를 확인해 주세요.'
                                          : homeState.searchQuery.isNotEmpty
                                              ? '검색어를 바꾸거나 초기화해 주세요.'
                                              : '뉴스 소스를 확인하거나 잠시 뒤 다시 시도해 주세요.',
                                )
                              : ListView(
                                  children: _buildArticleWidgets(
                                    homeState.visibleArticles,
                                    articleState,
                                  ),
                                ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
