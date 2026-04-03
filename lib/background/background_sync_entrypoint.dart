import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:sosigi/services/app_logger.dart';
import 'package:sosigi/services/local_store_service.dart';
import 'package:sosigi/services/news_refresh_service.dart';
import 'package:sosigi/services/notification_service.dart';

const MethodChannel _workerChannel = MethodChannel(
  'sosigi/background_sync_worker',
);
const Duration _backgroundRefreshTimeout = Duration(seconds: 90);

@pragma('vm:entry-point')
Future<void> backgroundSyncMain() async {
  WidgetsFlutterBinding.ensureInitialized();

  final store = LocalStoreService();

  try {
    await LocalStoreService.initialize();
    try {
      await NotificationService.instance.initialize();
    } catch (e, st) {
      AppLogger.error('BackgroundSync', 'notification initialize failed', e, st);
    }

    // WorkManager가 주기를 제어하므로 앱 내 cooldown을 우회한다.
    final result = await NewsRefreshService()
        .refresh(
          force: false,
          refreshOwner: 'background_workmanager',
        )
        .timeout(_backgroundRefreshTimeout);
    if (result.errorMessage != null) {
      AppLogger.error(
        'BackgroundSync',
        'refresh returned an error result',
        result.errorMessage,
      );
    }

    try {
      await store.saveLastBackgroundSyncResult({
        'ranAt': DateTime.now().toIso8601String(),
        'success': result.errorMessage == null,
        'skippedByCooldown': result.isSkippedByCooldown,
        'blockedByWifi': result.isBlockedByWifiPolicy,
        'newArticleCount': result.newArticleCount,
        'statusMessage': result.statusMessage,
        'errorMessage': result.errorMessage,
      });
    } catch (_) {
      // 진단 저장 실패가 워커 완료를 막지 않도록 한다.
    }

    await _completeBackgroundSync(
      success: result.errorMessage == null,
      message: result.statusMessage,
      error: result.errorMessage,
    );
  } on TimeoutException catch (e, st) {
    AppLogger.error('BackgroundSync', 'background sync timed out', e, st);

    try {
      await store.saveLastBackgroundSyncResult({
        'ranAt': DateTime.now().toIso8601String(),
        'success': false,
        'skippedByCooldown': false,
        'blockedByWifi': false,
        'newArticleCount': 0,
        'statusMessage': '뉴스 업데이트가 제한 시간 안에 끝나지 않았습니다.',
        'errorMessage': e.toString(),
      });
    } catch (_) {}

    await _completeBackgroundSync(
      success: false,
      message: '뉴스 업데이트가 제한 시간 안에 끝나지 않았습니다.',
      error: e.toString(),
    );
  } catch (e, st) {
    AppLogger.error('BackgroundSync', 'background sync failed', e, st);

    try {
      await store.saveLastBackgroundSyncResult({
        'ranAt': DateTime.now().toIso8601String(),
        'success': false,
        'skippedByCooldown': false,
        'blockedByWifi': false,
        'newArticleCount': 0,
        'statusMessage': '뉴스 업데이트에 실패했습니다.',
        'errorMessage': e.toString(),
      });
    } catch (_) {}

    await _completeBackgroundSync(
      success: false,
      message: '뉴스 업데이트에 실패했습니다.',
      error: e.toString(),
    );
  }
}

Future<void> _completeBackgroundSync({
  required bool success,
  required String message,
  required String? error,
}) async {
  try {
    await _workerChannel.invokeMethod<void>(
      'complete',
      <String, Object?>{
        'success': success,
        'message': message,
        'error': error,
      },
    );
  } catch (e, st) {
    AppLogger.error(
      'BackgroundSync',
      'failed to invoke native completion',
      e,
      st,
    );
  }
}
