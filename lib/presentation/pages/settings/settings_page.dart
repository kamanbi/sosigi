import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
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

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage>
    with WidgetsBindingObserver {
  bool _isBatteryOptimized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (Platform.isAndroid) {
      _checkBatteryOptimization();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && Platform.isAndroid) {
      _checkBatteryOptimization();
    }
  }

  Future<void> _checkBatteryOptimization() async {
    final optimized =
        await BackgroundSyncScheduler.instance.isBatteryOptimized();
    if (mounted) {
      setState(() => _isBatteryOptimized = optimized);
    }
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
                          activeColor: AppColors.navy,
                          activeTrackColor: AppColors.accent,
                        ),
                      ],
                    ),
                  ),
                ),
                SettingsSectionCard(
                  icon: Icons.history_rounded,
                  title: '자동 업데이트',
                  description: '갱신 주기',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          for (final option in const [
                            SyncIntervalOption.min15,
                            SyncIntervalOption.min30,
                            SyncIntervalOption.hour1,
                          ])
                            SettingChoiceChip(
                              label: option.label,
                              selected: settings.syncInterval == option,
                              onTap: () async {
                                await notifier.setSyncInterval(option);
                              },
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (Platform.isAndroid && _isBatteryOptimized)
                  SettingsSectionCard(
                    icon: Icons.battery_alert_rounded,
                    title: '배터리 최적화',
                    description: '백그라운드 업데이트 신뢰성',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SettingActionTile(
                          title: '배터리 최적화 예외 설정',
                          subtitle: '앱이 닫혀도 뉴스를 제때 받으려면 예외로 설정하세요',
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
                              Icon(
                                Icons.info_outline_rounded,
                                size: 13,
                                color: AppColors.secondaryText,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '키워드 알림을 받으려면 시스템 알림 권한도 승인해야 합니다.',
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
                SettingsSectionCard(
                  icon: Icons.notifications_active_outlined,
                  title: '키워드 관리',
                  description: '등록/해제/알림',
                  child: SettingActionTile(
                    title: '키워드 등록 열기',
                    subtitle: '등록, 해제, 알림 설정',
                    onTap: () {
                      Navigator.pushNamed(context, AppRouter.keywords);
                    },
                  ),
                ),
                SettingsSectionCard(
                  icon: Icons.folder_open_rounded,
                  title: '뉴스 소스',
                  description: '기사 공급처 선택',
                  child: SettingActionTile(
                    title: '뉴스 소스 선택',
                    subtitle: '출처별로 켜고 끌 수 있습니다',
                    onTap: () {
                      Navigator.pushNamed(context, AppRouter.newsSources);
                    },
                  ),
                ),
                SettingsSectionCard(
                  icon: Icons.analytics_outlined,
                  title: '진단',
                  description: '로그 및 상태 점검',
                  child: SettingActionTile(
                    title: '진단 화면 열기',
                    subtitle: '최근 로그, 기사 수, 동작 상태 확인',
                    onTap: () {
                      Navigator.pushNamed(context, AppRouter.diagnostics);
                    },
                  ),
                ),
                SettingsSectionCard(
                  icon: Icons.info_outline_rounded,
                  title: '앱 정보',
                  description: '문의 및 정책',
                  child: SettingActionTile(
                    title: '앱 정보 및 문의',
                    subtitle: '문의처, 웹페이지, 개인정보처리방침',
                    onTap: () {
                      Navigator.pushNamed(context, AppRouter.info);
                    },
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
