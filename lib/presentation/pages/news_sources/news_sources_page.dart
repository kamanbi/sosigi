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

  static const _compactCardPadding = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 8,
  );
  static const _compactCardMargin = EdgeInsets.only(bottom: 6);
  static const _compactDescriptionFontSize = 10.5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sources = ref.watch(newsSourceProvider);
    final notifier = ref.read(newsSourceProvider.notifier);
    final enabledCount = sources.where((source) => source.enabled).length;

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
                  margin: _compactCardMargin,
                  padding: _compactCardPadding,
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
                            if (_showsMergedDescription(source.id)) ...[
                              const SizedBox(height: 4),
                              Text(
                                _descriptionForSource(source.id),
                                style: AppTextStyles.sectionBody.copyWith(
                                  fontSize: _compactDescriptionFontSize,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Switch(
                        value: source.enabled,
                        onChanged: (_) => notifier.toggleSource(source.id),
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

  bool _showsMergedDescription(String sourceId) {
    return switch (sourceId) {
      'google' || 'yna' || 'mk' || 'newsis' || 'mbn' || 'fnnews' => true,
      _ => false,
    };
  }

  String _descriptionForSource(String sourceId) {
    return switch (sourceId) {
      'google' || 'yna' => '종합 · 정치 · 경제 · 사회 · 국제 · IT · 스포츠 · 연예',
      'mk' => '종합 · 경제 · 기업 · 증권',
      'newsis' => '경제 · 금융 · 산업',
      'mbn' => '종합 · 경제',
      'fnnews' => '종합 · 경제 · 증권',
      _ => '',
    };
  }
}
