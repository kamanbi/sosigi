import 'dart:io';

import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sosigi/services/app_logger.dart';

class UpdateCheckResult {
  const UpdateCheckResult({
    required this.hasUpdate,
    required this.isForced,
    this.currentVersion,
    this.latestVersion,
  });

  const UpdateCheckResult.noUpdate()
      : hasUpdate = false,
        isForced = false,
        currentVersion = null,
        latestVersion = null;

  final bool hasUpdate;
  final bool isForced;
  final String? currentVersion;
  final String? latestVersion;
}

abstract class UpdateCheckService {
  Future<UpdateCheckResult> check();
}

class InAppUpdateService implements UpdateCheckService {
  @override
  Future<UpdateCheckResult> check() async {
    if (!Platform.isAndroid) return const UpdateCheckResult.noUpdate();

    final packageInfo = await PackageInfo.fromPlatform();
    final updateInfo = await InAppUpdate.checkForUpdate();
    if (updateInfo.updateAvailability != UpdateAvailability.updateAvailable) {
      return const UpdateCheckResult.noUpdate();
    }

    return UpdateCheckResult(
      hasUpdate: true,
      isForced: false,
      currentVersion: packageInfo.version,
    );
  }

  Future<void> triggerUpdate() async {
    await InAppUpdate.performImmediateUpdate();
  }
}

class CombinedUpdateService {
  final InAppUpdateService _inAppUpdateService = InAppUpdateService();

  Future<UpdateCheckResult> check() async {
    try {
      return await _inAppUpdateService.check();
    } catch (e, st) {
      AppLogger.error(
        'CombinedUpdateService',
        'InAppUpdate check failed',
        e,
        st,
      );
      return const UpdateCheckResult.noUpdate();
    }
  }

  Future<void> triggerInAppUpdate() async {
    await _inAppUpdateService.triggerUpdate();
  }
}
