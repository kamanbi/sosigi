import 'package:flutter/services.dart';
import 'package:sosigi/domain/models/app_settings.dart';

class BackgroundSyncScheduler {
  BackgroundSyncScheduler._();

  static final BackgroundSyncScheduler instance = BackgroundSyncScheduler._();

  static const MethodChannel _channel = MethodChannel(
    'sosigi/background_sync',
  );

  Future<void> schedule(AppSettings settings) async {
    await _invoke(
      'schedule',
      <String, Object>{
        'intervalMinutes': settings.syncInterval.minutes,
        'wifiOnly': settings.wifiOnly,
      },
    );
  }

  Future<void> cancel() async {
    await _invoke('cancel', const <String, Object>{});
  }

  /// 배터리 최적화 대상 여부 확인 (Android 전용, 다른 플랫폼은 false 반환)
  Future<bool> isBatteryOptimized() async {
    try {
      return await _channel.invokeMethod<bool>('isBatteryOptimized') ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  /// 배터리 최적화 예외 요청 다이얼로그 표시 (Android 전용)
  Future<void> requestIgnoreBatteryOptimization() async {
    await _invoke('requestIgnoreBatteryOptimization', const <String, Object>{});
  }

  Future<void> openBatteryOptimizationSettings() async {
    await _invoke('openBatteryOptimizationSettings', const <String, Object>{});
  }

  Future<void> _invoke(String method, Map<String, Object> arguments) async {
    try {
      await _channel.invokeMethod<void>(method, arguments);
    } on MissingPluginException {
      return;
    } on PlatformException {
      return;
    }
  }
}
