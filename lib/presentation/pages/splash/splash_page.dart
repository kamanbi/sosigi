import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sosigi/app/router.dart';
import 'package:sosigi/app/theme/app_colors.dart';
import 'package:sosigi/app/theme/app_text_styles.dart';
import 'package:sosigi/services/app_logger.dart';
import 'package:sosigi/services/notification_service.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with WidgetsBindingObserver {
  static const String _appIconAsset =
      'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png';
  static const Duration _splashDelay = Duration(seconds: 2);

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
      _setLoadingLabel('앱을 준비하고 있습니다...');
      await Future<void>.delayed(_splashDelay);

      _setLoadingLabel('알림 권한을 확인하고 있습니다...');
      final permissionResult =
          await NotificationService.instance.ensurePermissionFlow();

      if (permissionResult.shouldOpenSettings && mounted) {
        await _showNotificationSettingsDialog(
          deniedCount: permissionResult.deniedCount,
        );
      }
    } catch (e, st) {
      AppLogger.error('SplashPage', 'startup flow failed', e, st);
    }

    if (!mounted || _navigated) return;
    _navigated = true;
    Navigator.pushReplacementNamed(context, AppRouter.home);
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
            '알림 권한을 $deniedCount회 거부하여 더 이상 자동 요청하지 않습니다. '
            '설정에서 권한을 허용하면 키워드 알림을 받을 수 있습니다.',
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

    _settingsReturnCompleter = Completer<void>();
    await NotificationService.instance.openNotificationSettings();
    await _settingsReturnCompleter!.future;
    _settingsReturnCompleter = null;
    await NotificationService.instance.syncPermissionState();
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
