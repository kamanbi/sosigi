import 'package:flutter/material.dart';
import 'package:sosigi/app/theme/app_colors.dart';
import 'package:sosigi/app/theme/app_text_styles.dart';
import 'package:sosigi/core/enums/home_category.dart';
import 'package:sosigi/presentation/widgets/common/bottom_banner_ad.dart';

class CategorySelectorSheet extends StatelessWidget {
  final HomeCategory selected;
  final ValueChanged<HomeCategory> onSelected;

  const CategorySelectorSheet({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    const categories = HomeCategory.values;

    return SafeArea(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.72,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 6,
              margin: const EdgeInsets.only(top: 14),
              decoration: BoxDecoration(
                color: AppColors.cardBorder,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '카테고리 선택',
                  style: AppTextStyles.pageTitle.copyWith(fontSize: 20),
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                itemCount: categories.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final active = category == selected;

                  return InkWell(
                    onTap: () {
                      onSelected(category);
                      Navigator.pop(context);
                    },
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      height: 58,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: active ? AppColors.navy : AppColors.inactive,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: active ? AppColors.navy : AppColors.cardBorder,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: active
                                  ? AppColors.surface.withValues(alpha: 0.16)
                                  : AppColors.surface,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.subdirectory_arrow_right_rounded,
                              color: active
                                  ? AppColors.surface
                                  : AppColors.secondaryText,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              category.label,
                              style: AppTextStyles.sectionTitle.copyWith(
                                fontSize: 14,
                                color: active
                                    ? AppColors.surface
                                    : AppColors.primaryText,
                              ),
                            ),
                          ),
                          if (active)
                            const Icon(
                              Icons.check_rounded,
                              color: AppColors.surface,
                              size: 22,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(
              height: 50,
              child: BottomBannerAd(),
            ),
          ],
        ),
      ),
    );
  }
}
