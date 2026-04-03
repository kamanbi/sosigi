import 'package:flutter/material.dart';
import 'package:sosigi/app/theme/app_colors.dart';
import 'package:sosigi/app/theme/app_text_styles.dart';

class KeywordChipBar extends StatelessWidget {
  final List<String> keywords;
  final String? selectedKeyword;
  final ValueChanged<String> onTap;

  const KeywordChipBar({
    super.key,
    required this.keywords,
    required this.selectedKeyword,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: keywords.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final keyword = keywords[index];
          final active = selectedKeyword == keyword;

          return GestureDetector(
            onTap: () => onTap(keyword),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              decoration: BoxDecoration(
                color: active ? AppColors.navy : AppColors.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: active ? AppColors.navy : AppColors.cardBorder,
                ),
              ),
              child: Center(
                child: Text(
                  keyword,
                  style: AppTextStyles.chip.copyWith(
                    color: active ? AppColors.surface : AppColors.primaryText,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}