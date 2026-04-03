import 'package:flutter/material.dart';
import 'package:sosigi/app/theme/app_colors.dart';
import 'package:sosigi/app/theme/app_text_styles.dart';
import 'package:sosigi/presentation/widgets/common/premium_card.dart';

class NetworkBlockCard extends StatelessWidget {
  const NetworkBlockCard({super.key});

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              color: AppColors.accentSoft,
              borderRadius: BorderRadius.circular(26),
            ),
            child: const Icon(
              Icons.wifi_lock_rounded,
              size: 42,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 22),
          Text(
            '현재 Wi-Fi 전용 모드가 켜져 있어요',
            textAlign: TextAlign.center,
            style: AppTextStyles.largeEmptyTitle,
          ),
          const SizedBox(height: 10),
          Text(
            '모바일 데이터에서는 뉴스를 불러오지 않습니다.\n옵션에서 설정을 변경할 수 있어요.',
            textAlign: TextAlign.center,
            style: AppTextStyles.largeEmptyBody,
          ),
        ],
      ),
    );
  }
}