import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sosigi/app/theme/app_colors.dart';
import 'package:sosigi/app/theme/app_text_styles.dart';
import 'package:sosigi/presentation/providers/article_state_provider.dart';
import 'package:sosigi/presentation/providers/home_provider.dart';
import 'package:sosigi/presentation/providers/news_source_provider.dart';
import 'package:sosigi/presentation/widgets/common/bottom_banner_ad.dart';
import 'package:sosigi/presentation/widgets/common/premium_card.dart';
import 'package:sosigi/presentation/widgets/common/sosigi_scaffold.dart';
import 'package:sosigi/services/app_logger.dart';
import 'package:sosigi/services/local_store_service.dart';

class DiagnosticsPage extends ConsumerStatefulWidget {
  const DiagnosticsPage({super.key});

  @override
  ConsumerState<DiagnosticsPage> createState() => _DiagnosticsPageState();
}

class _DiagnosticsPageState extends ConsumerState<DiagnosticsPage> {
  Map<String, dynamic>? _backgroundSyncResult;

  @override
  void initState() {
    super.initState();
    unawaited(ref.read(articleStateProvider.notifier).load());
    unawaited(_loadBackgroundSyncResult());
  }

  Future<void> _loadBackgroundSyncResult() async {
    final result = await LocalStoreService().loadLastBackgroundSyncResult();
    if (mounted) {
      setState(() {
        _backgroundSyncResult = result;
      });
    }
  }

  String _formatBackgroundSyncResult(Map<String, dynamic>? data) {
    if (data == null) return '백그라운드 sync: (기록 없음)';

    final ranAtRaw = data['ranAt'] as String?;
    final ranAt = ranAtRaw != null
        ? DateFormat('MM.dd HH:mm:ss').format(DateTime.parse(ranAtRaw).toLocal())
        : '?';
    final success = data['success'] as bool? ?? false;
    final skipped = data['skippedByCooldown'] as bool? ?? false;
    final blocked = data['blockedByWifi'] as bool? ?? false;
    final newCount = data['newArticleCount'] as int? ?? 0;
    final statusMsg = data['statusMessage'] as String? ?? '';
    final errorMsg = data['errorMessage'] as String?;

    final statusLabel = skipped
        ? 'cooldown skip'
        : blocked
            ? 'Wi-Fi 차단'
            : success
                ? '성공 (신규 $newCount건)'
                : '실패';

    final errorLine = errorMsg != null ? '\n백그라운드 에러: $errorMsg' : '';

    return '백그라운드 sync: $ranAt / $statusLabel / $statusMsg$errorLine';
  }

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homeProvider);
    final sources = ref.watch(newsSourceProvider);
    final articleState = ref.watch(articleStateProvider);

    final enabledCount = sources.where((e) => e.enabled).length;

    final sourceStats = <String, int>{};
    for (final article in homeState.allArticles) {
      sourceStats.update(
        article.sourceName,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }

    final sortedSourceStats = sourceStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return SosigiScaffold(
      bottomNavigationBar: const BottomBannerAd(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    size: 24,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(width: 2),
                Expanded(
                  child: Text(
                    '진단 화면',
                    style: AppTextStyles.pageTitle.copyWith(fontSize: 20),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    AppLogger.clear();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('로그를 비웠습니다.'),
                      ),
                    );
                  },
                  child: const Text('로그 비우기'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 2, 14, 14),
              children: [
                PremiumCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('현재 상태', style: AppTextStyles.sectionTitle),
                      const SizedBox(height: 12),
                      Text(
                        '전체 기사: ${homeState.allArticles.length}\n'
                        '표시 기사: ${homeState.visibleArticles.length}\n'
                        '활성 소스: $enabledCount / ${sources.length}\n'
                        '읽음 기사: ${articleState.readIds.length}\n'
                        '북마크 기사: ${articleState.bookmarkedIds.length}\n'
                        '검색어: ${homeState.searchQuery.isEmpty ? '(없음)' : homeState.searchQuery}\n'
                        '마지막 동기화: ${homeState.lastSyncAt == null ? '(없음)' : DateFormat('MM.dd HH:mm:ss').format(homeState.lastSyncAt!)}\n'
                        '최근 신규 기사 수: ${homeState.lastRefreshNewCount}\n'
                        '최근 상태 메시지: ${homeState.statusMessage ?? '(없음)'}\n'
                        '최근 에러: ${homeState.errorMessage ?? '(없음)'}\n'
                        '${_formatBackgroundSyncResult(_backgroundSyncResult)}',
                        style: AppTextStyles.sectionBody.copyWith(fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                PremiumCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('소스별 기사 수', style: AppTextStyles.sectionTitle),
                      const SizedBox(height: 12),
                      if (sortedSourceStats.isEmpty)
                        Text(
                          '표시할 통계가 없습니다.',
                          style: AppTextStyles.sectionBody,
                        )
                      else
                        ...sortedSourceStats.map(
                          (entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              '${entry.key}: ${entry.value}건',
                              style: AppTextStyles.sectionBody.copyWith(
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                PremiumCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('최근 로그', style: AppTextStyles.sectionTitle),
                      const SizedBox(height: 12),
                      ValueListenableBuilder<List<String>>(
                        valueListenable: AppLogger.logs,
                        builder: (context, logs, _) {
                          final recentLogs = logs
                              .where((line) => line.contains('[ERROR]'))
                              .toList(growable: false);

                          if (recentLogs.isEmpty) {
                            return Text(
                              '로그가 없습니다.',
                              style: AppTextStyles.sectionBody,
                            );
                          }

                          final recent = <String>[
                            ...recentLogs.reversed.take(40),
                          ];

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: recent.map((line) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  line,
                                  style: AppTextStyles.sectionBody.copyWith(
                                    fontSize: 12,
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
