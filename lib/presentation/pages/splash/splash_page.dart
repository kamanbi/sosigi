import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sosigi/app/router.dart';
import 'package:sosigi/app/theme/app_colors.dart';
import 'package:sosigi/app/theme/app_text_styles.dart';
import 'package:sosigi/services/app_logger.dart';
import 'package:sosigi/services/background_sync_scheduler.dart';
import 'package:sosigi/services/local_store_service.dart';
import 'package:sosigi/services/notification_service.dart';
import 'package:sosigi/services/update_check_service.dart';
import 'package:url_launcher/url_launcher.dart';

class _PermissionPromptDecision {
  const _PermissionPromptDecision({
    required this.shouldContinue,
    required this.suppressPrompt,
  });

  final bool shouldContinue;
  final bool suppressPrompt;
}

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with WidgetsBindingObserver {
  static const String _appIconAsset =
      'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png';
  static const Duration _splashDelay = Duration(seconds: 2);

  final LocalStoreService _store = LocalStoreService();

  bool _navigated = false;
  Completer<void>? _settingsReturnCompleter;
  String _loadingLabel = '앱을 준비하고 있습니다...';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_startFlow());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (!(_settingsReturnCompleter?.isCompleted ?? true)) {
      _settingsReturnCompleter?.complete();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    if (_settingsReturnCompleter?.isCompleted ?? true) return;
    _settingsReturnCompleter?.complete();
  }

  Future<void> _startFlow() async {
    try {
      _setLoadingLabel('업데이트를 확인하고 있습니다...');
      await _checkUpdate();

      _setLoadingLabel('앱을 준비하고 있습니다...');
      await Future<void>.delayed(_splashDelay);

      _setLoadingLabel('알림 권한을 확인하고 있습니다...');
      await _handleNotificationPermissionFlow();

      if (Platform.isAndroid) {
        _setLoadingLabel('백그라운드 허용 상태를 확인하고 있습니다...');
        await _handleBackgroundPermissionFlow();
      }
    } catch (e, st) {
      AppLogger.error('SplashPage', 'startup flow failed', e, st);
    }

    if (!mounted || _navigated) return;
    _navigated = true;
    Navigator.pushReplacementNamed(context, AppRouter.home);
  }

  Future<void> _checkUpdate() async {
    try {
      final service = CombinedUpdateService();
      final result = await service.check();
      if (!result.hasUpdate || !mounted) return;
      await _showUpdateDialog(result, service);
    } catch (e, st) {
      AppLogger.error('SplashPage', 'update check failed', e, st);
    }
  }

  Future<void> _showUpdateDialog(
    UpdateCheckResult result,
    CombinedUpdateService service,
  ) async {
    final isForced = result.isForced;
    await showDialog<void>(
      context: context,
      barrierDismissible: !isForced,
      builder: (context) {
        return PopScope(
          canPop: !isForced,
          child: AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: Text(
              isForced ? '필수 업데이트가 있습니다' : '새 버전이 출시되었습니다',
              style: AppTextStyles.sectionTitle.copyWith(fontSize: 18),
            ),
            content: Text(
              [
                if (result.currentVersion != null)
                  '현재 버전: ${result.currentVersion}',
                if (result.latestVersion != null)
                  '최신 버전: ${result.latestVersion}',
                if (isForced)
                  '\n계속 사용하려면 업데이트가 필요합니다.'
                else
                  '\n업데이트하면 최신 기능을 사용할 수 있습니다.',
              ].join('\n'),
              style: AppTextStyles.sectionBody.copyWith(fontSize: 13),
            ),
            actions: [
              if (!isForced)
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    '나중에',
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
                onPressed: () async {
                  Navigator.pop(context);
                  if (result.source == UpdateSource.inAppUpdate) {
                    await service.triggerInAppUpdate();
                  } else {
                    final url = Uri.tryParse(result.storeUrl ?? '');
                    if (url != null) {
                      await launchUrl(url,
                          mode: LaunchMode.externalApplication);
                    }
                  }
                },
                child: Text(
                  '업데이트',
                  style: AppTextStyles.button.copyWith(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleNotificationPermissionFlow() async {
    final isGranted = await NotificationService.instance.syncPermissionState();
    if (isGranted) return;

    final isSuppressed = await NotificationService.instance.isPromptSuppressed();
    if (isSuppressed || !mounted) return;

    final decision = await _showPermissionPromptDialog(
      title: '알림 권한을 허용해 주세요',
      message:
          '새로운 키워드 뉴스가 도착했을 때 알림창으로 바로 알려드리기 위해 알림 권한이 필요합니다.',
      confirmLabel: '알림 허용',
    );

    await NotificationService.instance.setPromptSuppressed(
      decision.suppressPrompt,
    );

    if (!decision.shouldContinue) return;

    final permissionResult =
        await NotificationService.instance.ensurePermissionFlow();

    if (permissionResult.shouldOpenSettings && mounted) {
      await _showNotificationSettingsDialog(
        deniedCount: permissionResult.deniedCount,
      );
    }
  }

  Future<void> _handleBackgroundPermissionFlow() async {
    final isBatteryOptimizationEnabled =
        await BackgroundSyncScheduler.instance.isBatteryOptimized();
    if (!isBatteryOptimizationEnabled) {
      await _store.saveBackgroundPromptSuppressed(false);
      return;
    }

    final isSuppressed = await _store.loadBackgroundPromptSuppressed();
    if (isSuppressed || !mounted) return;

    final decision = await _showPermissionPromptDialog(
      title: '백그라운드 허용을 허용해 주세요',
      message:
          '앱을 닫아도 자동 업데이트 주기에 맞춰 뉴스를 다시 확인하고, 새로운 키워드 뉴스가 생기면 알림을 보내기 위해 백그라운드 허용이 필요합니다.',
      confirmLabel: '백그라운드 허용',
    );

    await _store.saveBackgroundPromptSuppressed(decision.suppressPrompt);

    if (!decision.shouldContinue) return;

    await _awaitSystemSettingsReturn(
      () => BackgroundSyncScheduler.instance.requestIgnoreBatteryOptimization(),
    );

    final isStillOptimized =
        await BackgroundSyncScheduler.instance.isBatteryOptimized();
    if (!isStillOptimized) {
      await _store.saveBackgroundPromptSuppressed(false);
    }
  }

  void _setLoadingLabel(String value) {
    if (!mounted) return;
    setState(() {
      _loadingLabel = value;
    });
  }

  Future<void> _showNotificationSettingsDialog({
    required int deniedCount,
  }) async {
    final shouldOpenSettings = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            '알림 권한이 꺼져 있어요',
            style: AppTextStyles.sectionTitle.copyWith(fontSize: 18),
          ),
          content: Text(
            '알림 권한을 $deniedCount회 거부하여 더 이상 자동 요청하지 않습니다. 설정에서 권한을 허용하면 새로운 키워드 뉴스를 알림창으로 바로 받을 수 있습니다.',
            style: AppTextStyles.sectionBody.copyWith(fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                '나중에',
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
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                '설정으로 이동',
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

    if (shouldOpenSettings != true) return;

    await _awaitSystemSettingsReturn(
      NotificationService.instance.openNotificationSettings,
    );
    await NotificationService.instance.syncPermissionState();
  }

  Future<_PermissionPromptDecision> _showPermissionPromptDialog({
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    final result = await showDialog<_PermissionPromptDecision>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        var suppressPrompt = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: Text(
                title,
                style: AppTextStyles.sectionTitle.copyWith(fontSize: 18),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: AppTextStyles.sectionBody.copyWith(fontSize: 13),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Checkbox(
                        value: suppressPrompt,
                        onChanged: (value) {
                          setDialogState(() {
                            suppressPrompt = value ?? false;
                          });
                        },
                      ),
                      Expanded(
                        child: Text(
                          '다음엔 자동으로 다시 묻지 않음',
                          style: AppTextStyles.sectionBody.copyWith(
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                      _PermissionPromptDecision(
                        shouldContinue: false,
                        suppressPrompt: suppressPrompt,
                      ),
                    );
                  },
                  child: Text(
                    '나중에',
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
                      _PermissionPromptDecision(
                        shouldContinue: true,
                        suppressPrompt: suppressPrompt,
                      ),
                    );
                  },
                  child: Text(
                    confirmLabel,
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

    return result ??
        const _PermissionPromptDecision(
          shouldContinue: false,
          suppressPrompt: false,
        );
  }

  Future<void> _awaitSystemSettingsReturn(Future<void> Function() action) async {
    _settingsReturnCompleter = Completer<void>();
    await action();
    await _settingsReturnCompleter!.future;
    _settingsReturnCompleter = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 96,
                height: 96,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Image.asset(
                    _appIconAsset,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '소식이',
                style: AppTextStyles.pageTitle.copyWith(fontSize: 24),
              ),
              const SizedBox(height: 8),
              Text(
                '맞춤형 뉴스 브리핑',
                style: AppTextStyles.sectionBody.copyWith(fontSize: 14),
              ),
              const SizedBox(height: 26),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: const LinearProgressIndicator(
                  minHeight: 6,
                  backgroundColor: AppColors.cardBorder,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.navy),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _loadingLabel,
                textAlign: TextAlign.center,
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
