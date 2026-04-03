import 'package:flutter/material.dart';
import 'package:sosigi/app/theme/app_colors.dart';
import 'package:sosigi/app/theme/app_text_styles.dart';

class DataWarningDialog extends StatefulWidget {
  final ValueChanged<bool> onConfirm;

  const DataWarningDialog({
    super.key,
    required this.onConfirm,
  });

  @override
  State<DataWarningDialog> createState() => _DataWarningDialogState();
}

class _DataWarningDialogState extends State<DataWarningDialog> {
  bool dontShowAgain = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('데이터 사용 주의', style: AppTextStyles.pageTitle),
            const SizedBox(height: 14),
            Text(
              '모바일 데이터로 뉴스를 불러오면\n과도한 요금이 발생할 수 있습니다.',
              textAlign: TextAlign.center,
              style: AppTextStyles.sectionBody.copyWith(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Checkbox(
                  value: dontShowAgain,
                  onChanged: (value) {
                    setState(() {
                      dontShowAgain = value ?? false;
                    });
                  },
                ),
                Expanded(
                  child: Text(
                    '다음부터 표시하지 않기',
                    style: AppTextStyles.sectionBody.copyWith(
                      color: AppColors.primaryText,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('취소', style: AppTextStyles.button),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.navy,
                      foregroundColor: AppColors.surface,
                    ),
                    onPressed: () {
                      widget.onConfirm(dontShowAgain);
                      Navigator.pop(context);
                    },
                    child: Text(
                      '확인',
                      style: AppTextStyles.button.copyWith(
                        color: AppColors.surface,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}