import 'package:flutter/material.dart';
import 'package:sosigi/app/theme/app_colors.dart';

class BannerAdSlot extends StatelessWidget {
  final String label;

  const BannerAdSlot({
    super.key,
    this.label = '배너 광고 영역',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 82,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Center(child: Text(label)),
    );
  }
}