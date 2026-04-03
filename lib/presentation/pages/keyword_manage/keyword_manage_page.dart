import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sosigi/app/theme/app_colors.dart';
import 'package:sosigi/app/theme/app_text_styles.dart';
import 'package:sosigi/presentation/providers/keyword_provider.dart';
import 'package:sosigi/presentation/widgets/common/bottom_banner_ad.dart';
import 'package:sosigi/presentation/widgets/common/premium_card.dart';
import 'package:sosigi/presentation/widgets/common/sosigi_scaffold.dart';
import 'package:sosigi/services/background_sync_scheduler.dart';
import 'package:sosigi/services/notification_service.dart';

class KeywordManagePage extends ConsumerStatefulWidget {
  const KeywordManagePage({super.key});

  @override
  ConsumerState<KeywordManagePage> createState() => _KeywordManagePageState();
}

class _KeywordManagePageState extends ConsumerState<KeywordManagePage> {
  final TextEditingController _controller = TextEditingController();

  bool _notificationGranted = true;
  bool _batteryOptimized = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    bool notifGranted;
    bool batteryOptimized;

    try {
      notifGranted = await NotificationService.instance.syncPermissionState();
    } catch (_) {
      notifGranted = false;
    }

    try {
      batteryOptimized = Platform.isAndroid
          ? await BackgroundSyncScheduler.instance.isBatteryOptimized()
          : false;
    } catch (_) {
      batteryOptimized = false;
    }

    if (mounted) {
      setState(() {
        _notificationGranted = notifGranted;
        _batteryOptimized = batteryOptimized;
      });
    }
  }

  Future<void> _requestNotificationPermission() async {
    await NotificationService.instance.ensurePermissionFlow();
    await _checkPermissions();
  }

  Future<void> _requestBatteryOptimizationException() async {
    await BackgroundSyncScheduler.instance.requestIgnoreBatteryOptimization();
    await _checkPermissions();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    ref.read(keywordProvider.notifier).addKeyword(text);
    _controller.clear();
    FocusScope.of(context).unfocus();
  }

  bool get _hasMissingPermission =>
      !_notificationGranted || _batteryOptimized;

  @override
  Widget build(BuildContext context) {
    final keywords = ref.watch(keywordProvider);

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
                Text(
                  '키워드 등록',
                  style: AppTextStyles.pageTitle.copyWith(fontSize: 20),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 2, 14, 14),
              children: [
                if (_hasMissingPermission) ...[
                  _NotificationPermissionBanner(
                    notificationGranted: _notificationGranted,
                    batteryOptimized: _batteryOptimized,
                    onRequestNotification: _requestNotificationPermission,
                    onRequestBatteryException:
                        _requestBatteryOptimizationException,
                  ),
                  const SizedBox(height: 10),
                ],
                PremiumCard(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '새 키워드 등록',
                        style:
                            AppTextStyles.sectionTitle.copyWith(fontSize: 14),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 52,
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(16),
                                border:
                                    Border.all(color: AppColors.cardBorder),
                              ),
                              child: TextField(
                                controller: _controller,
                                style:
                                    AppTextStyles.body.copyWith(fontSize: 14),
                                decoration: const InputDecoration(
                                  hintText: '등록할 키워드를 입력하세요',
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 14,
                                  ),
                                ),
                                onSubmitted: (_) => _submit(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 82,
                            height: 52,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.navy,
                                foregroundColor: AppColors.surface,
                              ),
                              onPressed: _submit,
                              child: Text(
                                '등록',
                                style: AppTextStyles.button.copyWith(
                                  color: AppColors.surface,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                if (keywords.isEmpty)
                  PremiumCard(
                    padding: const EdgeInsets.all(12),
                    child: SizedBox(
                      height: 220,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.sell_outlined,
                            size: 52,
                            color: AppColors.secondaryText,
                          ),
                          const SizedBox(height: 14),
                          Text(
                            '등록된 키워드가 아직 없습니다.',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.largeEmptyTitle,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '위 입력창에서 키워드를 등록해 보세요.',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.largeEmptyBody,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...keywords.map((keyword) {
                    return PremiumCard(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              keyword.name,
                              style: AppTextStyles.sectionTitle.copyWith(
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Switch(
                            value: keyword.notificationEnabled,
                            onChanged: (value) => ref
                                .read(keywordProvider.notifier)
                                .setNotificationEnabled(keyword.id, value),
                            activeColor: AppColors.navy,
                            activeTrackColor: AppColors.accent,
                          ),
                          IconButton(
                            onPressed: () {
                              ref
                                  .read(keywordProvider.notifier)
                                  .removeKeyword(keyword.id);
                            },
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              color: AppColors.secondaryText,
                              size: 22,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationPermissionBanner extends StatelessWidget {
  const _NotificationPermissionBanner({
    required this.notificationGranted,
    required this.batteryOptimized,
    required this.onRequestNotification,
    required this.onRequestBatteryException,
  });

  final bool notificationGranted;
  final bool batteryOptimized;
  final VoidCallback onRequestNotification;
  final VoidCallback onRequestBatteryException;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFCC02)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 18,
                color: Color(0xFFF59E0B),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '키워드 알림을 받으려면 아래 두 항목을 모두 허용해야 합니다.',
                  style: AppTextStyles.sectionBody.copyWith(
                    fontSize: 12,
                    color: const Color(0xFF92400E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _PermissionRow(
            label: '알림 권한',
            granted: notificationGranted,
            actionLabel: '허용하기',
            onTap: notificationGranted ? null : onRequestNotification,
          ),
          if (Platform.isAndroid) ...[
            const SizedBox(height: 6),
            _PermissionRow(
              label: '배터리 최적화 예외',
              granted: !batteryOptimized,
              actionLabel: '예외 설정',
              onTap: batteryOptimized ? onRequestBatteryException : null,
            ),
          ],
        ],
      ),
    );
  }
}

class _PermissionRow extends StatelessWidget {
  const _PermissionRow({
    required this.label,
    required this.granted,
    required this.actionLabel,
    required this.onTap,
  });

  final String label;
  final bool granted;
  final String actionLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          granted ? Icons.check_circle_rounded : Icons.cancel_rounded,
          size: 16,
          color: granted
              ? const Color(0xFF16A34A)
              : const Color(0xFFDC2626),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.sectionBody.copyWith(
              fontSize: 13,
              color: const Color(0xFF78350F),
            ),
          ),
        ),
        if (!granted)
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.navy,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                actionLabel,
                style: AppTextStyles.button.copyWith(
                  fontSize: 11,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
