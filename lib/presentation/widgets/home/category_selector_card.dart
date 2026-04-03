import 'package:flutter/material.dart';
import 'package:sosigi/app/theme/app_colors.dart';
import 'package:sosigi/app/theme/app_text_styles.dart';
import 'package:sosigi/core/enums/home_category.dart';
import 'package:sosigi/presentation/widgets/home/category_selector_sheet.dart';

class CategorySelectorCard extends StatelessWidget {
  final HomeCategory selectedCategory;
  final ValueChanged<HomeCategory> onSelected;

  const CategorySelectorCard({
    super.key,
    required this.selectedCategory,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () async {
        await showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (_) {
            return CategorySelectorSheet(
              selected: selectedCategory,
              onSelected: onSelected,
            );
          },
        );
      },
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.accentSoft,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: const [
            BoxShadow(
              color: AppColors.heroShadow,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.apps_rounded,
                size: 16,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                selectedCategory.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.sectionTitle.copyWith(
                  fontSize: 14,
                  color: AppColors.navy,
                ),
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.navy,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
