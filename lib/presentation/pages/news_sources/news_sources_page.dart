import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sosigi/app/theme/app_colors.dart';
import 'package:sosigi/app/theme/app_text_styles.dart';
import 'package:sosigi/presentation/providers/news_source_provider.dart';
import 'package:sosigi/presentation/widgets/common/bottom_banner_ad.dart';
import 'package:sosigi/presentation/widgets/common/premium_card.dart';
import 'package:sosigi/presentation/widgets/common/sosigi_scaffold.dart';

class NewsSourcesPage extends ConsumerWidget {
  const NewsSourcesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sources = ref.watch(newsSourceProvider);
    final notifier = ref.read(newsSourceProvider.notifier);
    final enabledCount = sources.where((e) => e.enabled).length;

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
                    '뉴스 소스 선택',
                    style: AppTextStyles.pageTitle.copyWith(fontSize: 20),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: PremiumCard(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '선택됨 $enabledCount / ${sources.length}',
                      style: AppTextStyles.sectionTitle.copyWith(fontSize: 14),
                    ),
                  ),
                  SizedBox(
                    height: 38,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.navy,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: notifier.enableAll,
                      child: Text(
                        '전체 ON',
                        style: AppTextStyles.button.copyWith(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              itemCount: sources.length,
              itemBuilder: (context, index) {
                final source = sources[index];

                return PremiumCard(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              source.provider,
                              style: AppTextStyles.sectionTitle.copyWith(
                                fontSize: 14,
                              ),
                            ),
                            if (source.id == 'google') ...[
                              const SizedBox(height: 4),
                              Text(
                                '종합 · 정치 · 경제 · 사회 · 국제 · IT · 스포츠 · 연예',
                                style: AppTextStyles.sectionBody.copyWith(
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Switch(
                        value: source.enabled,
                        onChanged: (_) {
                          notifier.toggleSource(source.id);
                        },
                        activeColor: AppColors.navy,
                        activeTrackColor: AppColors.accent,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
