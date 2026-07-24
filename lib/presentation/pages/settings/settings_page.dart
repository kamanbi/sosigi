import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sosigi/app/router.dart';
import 'package:sosigi/app/theme/app_colors.dart';
import 'package:sosigi/app/theme/app_text_styles.dart';
import 'package:sosigi/domain/models/app_settings.dart';
import 'package:sosigi/presentation/providers/app_settings_provider.dart';
import 'package:sosigi/presentation/providers/home_provider.dart';
import 'package:sosigi/presentation/widgets/common/bottom_banner_ad.dart';
import 'package:sosigi/presentation/widgets/common/sosigi_scaffold.dart';
import 'package:sosigi/presentation/widgets/settings/data_warning_dialog.dart';
import 'package:sosigi/presentation/widgets/settings/setting_action_tile.dart';
import 'package:sosigi/presentation/widgets/settings/setting_choice_chip.dart';
import 'package:sosigi/presentation/widgets/settings/settings_section_card.dart';
import 'package:sosigi/services/background_sync_scheduler.dart';
import 'package:sosigi/services/notification_service.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage>
    with WidgetsBindingObserver {
  static const double _syncPickerItemExtent = 72;
  static const double _syncPickerValueFontSize = 48;
  static const double _syncPickerHeight = 196;

  bool _isCheckingNotificationPermission = true;
  bool _isNotificationGranted = false;
  bool _isBatteryOptimized = false;
  bool get _showLegacyBatteryOptimizationCard => false;

  static final List<int> _syncHourOptions = List<int>.generate(25, (i) => i);
  static const List<int> _syncMinuteOptions = <int>[0, 30];
  static final List<int> _quietHourOptions = List<int>.generate(24, (i) => i);
  static final List<int> _quietMinuteOptions = List<int>.generate(60, (i) => i);

  List<int> _availableSyncMinuteOptions(int hour) {
    if (hour == 0) return const <int>[30];
    if (hour == 24) return const <int>[0];
    return _syncMinuteOptions;
  }

  TimeOfDay _toTimeOfDay(NotificationQuietTime value) {
    return TimeOfDay(hour: value.hour, minute: value.minute);
  }

  String _formatQuietTime(
    BuildContext context,
    NotificationQuietTime value,
  ) {
    return MaterialLocalizations.of(context).formatTimeOfDay(
      _toTimeOfDay(value),
      alwaysUse24HourFormat: true,
    );
  }

  Future<void> _pickSyncInterval({
    required BuildContext context,
    required SyncIntervalOption initialValue,
    required Future<void> Function(SyncIntervalOption value) onConfirmed,
  }) async {
    var selectedHour = initialValue.hourValue;
    var selectedMinute = initialValue.minuteValue;
    final hourController = FixedExtentScrollController(
      initialItem: _syncHourOptions.indexOf(selectedHour),
    );
    final minuteController = FixedExtentScrollController(
      initialItem: _availableSyncMinuteOptions(
        selectedHour,
      ).indexOf(selectedMinute),
    );
    SyncIntervalOption? pickedValue;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final minuteOptions = _availableSyncMinuteOptions(selectedHour);

            if (!minuteOptions.contains(selectedMinute)) {
              selectedMinute = minuteOptions.first;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!minuteController.hasClients) return;
                minuteController.jumpToItem(
                  minuteOptions.indexOf(selectedMinute),
                );
              });
            }

            return Dialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '자동 업데이트 주기',
                      style: AppTextStyles.sectionTitle.copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '30분부터 24시간까지, 30분 단위로 설정할 수 있습니다.',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.inactive,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  '시간',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.secondaryText,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  height: _syncPickerHeight,
                                  child: CupertinoPicker(
                                    scrollController: hourController,
                                    itemExtent: _syncPickerItemExtent,
                                    useMagnifier: false,
                                    onSelectedItemChanged: (index) {
                                      setDialogState(() {
                                        selectedHour = _syncHourOptions[index];
                                      });
                                    },
                                    children: [
                                      for (final hour in _syncHourOptions)
                                        Center(
                                          child: Text(
                                            hour.toString().padLeft(2, '0'),
                                            style: AppTextStyles.pageTitle
                                                .copyWith(
                                              fontSize:
                                                  _syncPickerValueFontSize,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 176,
                            color: AppColors.cardBorder,
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  '분',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.secondaryText,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  height: _syncPickerHeight,
                                  child: CupertinoPicker(
                                    key: ValueKey<int>(selectedHour),
                                    scrollController: minuteController,
                                    itemExtent: _syncPickerItemExtent,
                                    useMagnifier: false,
                                    onSelectedItemChanged: (index) {
                                      setDialogState(() {
                                        selectedMinute = minuteOptions[index];
                                      });
                                    },
                                    children: [
                                      for (final minute in minuteOptions)
                                        Center(
                                          child: Text(
                                            minute.toString().padLeft(2, '0'),
                                            style: AppTextStyles.pageTitle
                                                .copyWith(
                                              fontSize:
                                                  _syncPickerValueFontSize,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('취소'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.navy,
                            ),
                            onPressed: () {
                              pickedValue = SyncIntervalOption.fromWheelValues(
                                hour: selectedHour,
                                minute: selectedMinute,
                              );
                              Navigator.pop(context);
                            },
                            child: const Text('저장'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    hourController.dispose();
    minuteController.dispose();

    if (pickedValue == null) return;
    await onConfirmed(pickedValue!);
  }

  Future<void> _pickQuietTime({
    required BuildContext context,
    required NotificationQuietTime initialValue,
    required Future<void> Function(NotificationQuietTime value) onConfirmed,
  }) async {
    var selectedHour = initialValue.hour;
    var selectedMinute = initialValue.minute;

    final picked = await showDialog<NotificationQuietTime>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: Text(
                '시간 선택',
                style: AppTextStyles.sectionTitle.copyWith(fontSize: 18),
              ),
              content: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: selectedHour,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: '시'),
                      items: [
                        for (final hour in _quietHourOptions)
                          DropdownMenuItem<int>(
                            value: hour,
                            child: Text(hour.toString().padLeft(2, '0')),
                          ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() {
                          selectedHour = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: selectedMinute,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: '분'),
                      items: [
                        for (final minute in _quietMinuteOptions)
                          DropdownMenuItem<int>(
                            value: minute,
                            child: Text(minute.toString().padLeft(2, '0')),
                          ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() {
                          selectedMinute = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    '취소',
                    style: AppTextStyles.button.copyWith(
                      color: AppColors.secondaryText,
                      fontSize: 14,
                    ),
                  ),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(
                      context,
                      NotificationQuietTime(
                        hour: selectedHour,
                        minute: selectedMinute,
                      ),
                    );
                  },
                  child: Text(
                    '저장',
                    style: AppTextStyles.button.copyWith(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (picked == null) return;

    await onConfirmed(picked);
  }

  Widget _buildQuietHoursTile({
    required BuildContext context,
    required String title,
    required NotificationQuietTime value,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.inactive,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.sectionTitle.copyWith(fontSize: 13),
              ),
              const SizedBox(height: 8),
              Text(
                _formatQuietTime(context, value),
                style: AppTextStyles.pageTitle.copyWith(
                  fontSize: 18,
                  color: AppColors.navy,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_refreshPermissionStates());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refreshPermissionStates());
    }
  }

  Future<void> _refreshPermissionStates() async {
    final notificationGranted =
        await NotificationService.instance.syncPermissionState();
    final optimized = Platform.isAndroid
        ? await BackgroundSyncScheduler.instance.isBatteryOptimized()
        : false;

    if (mounted) {
      setState(() {
        _isCheckingNotificationPermission = false;
        _isNotificationGranted = notificationGranted;
        _isBatteryOptimized = optimized;
      });
    }
  }

  Future<void> _requestNotificationPermission() async {
    if (_isCheckingNotificationPermission) return;
    if (_isNotificationGranted) {
      await NotificationService.instance.openNotificationSettings();
      await _refreshPermissionStates();
      return;
    }

    final result = await NotificationService.instance.ensurePermissionFlow();
    if (!result.isGranted && result.shouldOpenSettings) {
      await NotificationService.instance.openNotificationSettings();
    }
    await _refreshPermissionStates();
  }

  Future<void> _requestBackgroundPermission() async {
    if (!_isBatteryOptimized) {
      await BackgroundSyncScheduler.instance.openBatteryOptimizationSettings();
      await _refreshPermissionStates();
      return;
    }

    await BackgroundSyncScheduler.instance.requestIgnoreBatteryOptimization();
    await _refreshPermissionStates();
  }

  Future<void> _refreshIfNetworkReady() async {
    final results = await Connectivity().checkConnectivity();
    final hasNetwork = results.any(
      (result) => result != ConnectivityResult.none,
    );

    if (!hasNetwork) return;

    await ref.read(homeProvider.notifier).refresh(
          force: true,
          userInitiated: true,
        );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
    final notifier = ref.read(appSettingsProvider.notifier);
    final quietHours = settings.notificationQuietHours;

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
                  '옵션',
                  style: AppTextStyles.pageTitle.copyWith(fontSize: 20),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 2, 14, 14),
              children: [
                SettingsSectionCard(
                  icon: Icons.wifi_rounded,
                  title: '네트워크',
                  description: '데이터 사용 정책',
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.inactive,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Wi-Fi 에서만 뉴스 불러오기',
                            style: AppTextStyles.sectionTitle.copyWith(
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Switch(
                          value: settings.wifiOnly,
                          onChanged: (value) async {
                            if (!value) {
                              if (settings.suppressMobileDataWarning) {
                                await notifier.setWifiOnly(false);
                                await _refreshIfNetworkReady();
                                return;
                              }

                              if (!context.mounted) return;

                              await showDialog(
                                context: context,
                                builder: (_) => DataWarningDialog(
                                  onConfirm: (dontShowAgain) async {
                                    await notifier.setWifiOnly(false);
                                    if (dontShowAgain) {
                                      await notifier
                                          .setSuppressMobileDataWarning(true);
                                    }
                                    await _refreshIfNetworkReady();
                                  },
                                ),
                              );
                              return;
                            }

                            await notifier.setWifiOnly(true);
                            await _refreshIfNetworkReady();
                          },
                          activeThumbColor: AppColors.navy,
                          activeTrackColor: AppColors.accent,
                        ),
                      ],
                    ),
                  ),
                ),
                SettingsSectionCard(
                  icon: Icons.history_rounded,
                  title: '자동 업데이트',
                  description: '알림주기와 동일합니다.',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () async {
                      await _pickSyncInterval(
                        context: context,
                        initialValue: settings.syncInterval,
                        onConfirmed: notifier.setSyncInterval,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.inactive,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '현재 업데이트 주기',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.secondaryText,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  settings.syncInterval.label,
                                  style: AppTextStyles.pageTitle.copyWith(
                                    fontSize: 20,
                                    color: AppColors.navy,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '탭해서 슬롯 방식으로 변경',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.secondaryText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.keyboard_arrow_up_rounded,
                            color: AppColors.secondaryText,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_showLegacyBatteryOptimizationCard &&
                    Platform.isAndroid &&
                    _isBatteryOptimized)
                  SettingsSectionCard(
                    icon: Icons.battery_alert_rounded,
                    title: '배터리 최적화',
                    description: '백그라운드 업데이트 허용',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SettingActionTile(
                          title: '배터리 최적화 예외 설정',
                          subtitle: '앱이 꺼져 있어도 뉴스를 받으려면 예외로 설정하세요.',
                          onTap: () async {
                            await BackgroundSyncScheduler.instance
                                .requestIgnoreBatteryOptimization();
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(4, 6, 4, 2),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.info_outline_rounded,
                                size: 13,
                                color: AppColors.secondaryText,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '뉴스를 안정적으로 받으려면 시스템 배터리 제한 예외가 필요할 수 있습니다.',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.secondaryText,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                // 3. 뉴스 보관 기간
                SettingsSectionCard(
                  icon: Icons.access_time_rounded,
                  title: '뉴스 보관 기간',
                  description: '최대 유지 시간',
                  child: Row(
                    children: [
                      for (final option in RetentionOption.values)
                        SettingChoiceChip(
                          label: option.label,
                          selected: settings.retentionOption == option,
                          onTap: () async {
                            await notifier.setRetentionOption(option);
                          },
                        ),
                    ],
                  ),
                ),
                // 4. 키워드 관리
                SettingsSectionCard(
                  icon: Icons.notifications_active_outlined,
                  title: '키워드 관리',
                  description: '등록, 해제, 알림 설정',
                  child: SettingActionTile(
                    title: '키워드 등록 열기',
                    subtitle: '등록, 해제, 알림 설정',
                    onTap: () {
                      Navigator.pushNamed(context, AppRouter.keywords);
                    },
                  ),
                ),
                // 5. 알림 금지 시간
                SettingsSectionCard(
                  icon: Icons.notifications_paused_outlined,
                  title: '알림 금지 시간',
                  description: '지정한 시간대에는 알림만 차단',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _buildQuietHoursTile(
                            context: context,
                            title: '시작',
                            value: quietHours.start,
                            onTap: () async {
                              await _pickQuietTime(
                                context: context,
                                initialValue: quietHours.start,
                                onConfirmed:
                                    notifier.setNotificationQuietHoursStart,
                              );
                            },
                          ),
                          const SizedBox(width: 10),
                          _buildQuietHoursTile(
                            context: context,
                            title: '종료',
                            value: quietHours.end,
                            onTap: () async {
                              await _pickQuietTime(
                                context: context,
                                initialValue: quietHours.end,
                                onConfirmed:
                                    notifier.setNotificationQuietHoursEnd,
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          '기본값은 18:00~07:00이며, 이 시간대에는 기사 수집은 계속하고 알림만 차단합니다.',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // 6. 뉴스 소스
                SettingsSectionCard(
                  icon: Icons.folder_open_rounded,
                  title: '뉴스 소스',
                  description: '기사 공급처 선택',
                  child: SettingActionTile(
                    title: '뉴스 소스 선택',
                    subtitle: '출처별로 켜고 끌 수 있습니다.',
                    onTap: () {
                      Navigator.pushNamed(context, AppRouter.newsSources);
                    },
                  ),
                ),
                // 7. 권한 및 백그라운드
                SettingsSectionCard(
                  icon: Icons.security_rounded,
                  title: '권한 및 백그라운드',
                  description: '알림과 백그라운드 허용 상태 확인',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SettingActionTile(
                        title:
                            _isNotificationGranted ? '알림 권한 설정됨' : '알림 권한 허용하기',
                        subtitle: _isNotificationGranted
                            ? '새로운 키워드 뉴스가 생기면 알림창으로 바로 안내됩니다.'
                            : '새로운 키워드 뉴스가 도착했을 때 알림창으로 바로 받기 위해 필요합니다.',
                        onTap: _requestNotificationPermission,
                      ),
                      if (Platform.isAndroid) ...[
                        const SizedBox(height: 8),
                        SettingActionTile(
                          title: _isBatteryOptimized
                              ? '백그라운드 허용하기'
                              : '백그라운드 허용 설정됨',
                          subtitle: _isBatteryOptimized
                              ? '앱을 닫아도 자동 업데이트 주기에 맞춰 뉴스를 다시 확인하고 키워드 알림을 보내려면 필요합니다.'
                              : '앱이 닫혀 있어도 자동 업데이트와 키워드 알림이 계속 동작합니다.',
                          onTap: _requestBackgroundPermission,
                        ),
                      ],
                    ],
                  ),
                ),
                // 8. 앱 정보 (진단 포함)
                SettingsSectionCard(
                  icon: Icons.info_outline_rounded,
                  title: '앱 정보',
                  description: '문의, 정책 및 진단',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SettingActionTile(
                        title: '앱 정보 및 문의',
                        subtitle: '문의처와 개인정보처리방침을 확인합니다.',
                        onTap: () {
                          Navigator.pushNamed(context, AppRouter.info);
                        },
                      ),
                      const SizedBox(height: 8),
                      SettingActionTile(
                        title: '진단 화면 열기',
                        subtitle: '최근 로그와 동작 상태를 확인합니다.',
                        onTap: () {
                          Navigator.pushNamed(context, AppRouter.diagnostics);
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
