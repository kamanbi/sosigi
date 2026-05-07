import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sosigi/services/app_logger.dart';

class UpdateCheckResult {
  final bool hasUpdate;
  final bool isForced;
  final String? currentVersion;
  final String? latestVersion;
  final String? storeUrl;
  final UpdateSource source;

  const UpdateCheckResult({
    required this.hasUpdate,
    required this.isForced,
    required this.source,
    this.currentVersion,
    this.latestVersion,
    this.storeUrl,
  });

  const UpdateCheckResult.noUpdate()
      : hasUpdate = false,
        isForced = false,
        source = UpdateSource.none,
        currentVersion = null,
        latestVersion = null,
        storeUrl = null;
}

enum UpdateSource { none, supabase, inAppUpdate }

abstract class UpdateCheckService {
  Future<UpdateCheckResult> check();
}

// ─── 방식 2: Supabase 강제 업데이트 ─────────────────────────────────────────

class SupabaseUpdateService implements UpdateCheckService {
  static const _table = 'app_versions';
  static const _storeUrl =
      'https://play.google.com/store/apps/details?id=com.kaman.sosigi';

  @override
  Future<UpdateCheckResult> check() async {
    if (!Platform.isAndroid) return const UpdateCheckResult.noUpdate();

    final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
    final supabaseKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
    if (supabaseUrl.isEmpty || supabaseKey.isEmpty) {
      AppLogger.info('SupabaseUpdateService', 'Supabase env not configured');
      return const UpdateCheckResult.noUpdate();
    }

    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;

    final client = Supabase.instance.client;
    final data = await client
        .from(_table)
        .select()
        .eq('platform', 'android')
        .maybeSingle();

    if (data == null) return const UpdateCheckResult.noUpdate();

    final latestVersion = data['latest_version'] as String? ?? '';
    final minVersion = data['min_version'] as String? ?? '';
    final forceUpdate = data['force_update'] as bool? ?? false;
    final storeUrl = data['store_url'] as String? ?? _storeUrl;

    if (forceUpdate && _isOlderThan(currentVersion, minVersion)) {
      return UpdateCheckResult(
        hasUpdate: true,
        isForced: true,
        source: UpdateSource.supabase,
        currentVersion: currentVersion,
        latestVersion: latestVersion,
        storeUrl: storeUrl,
      );
    }

    if (_isOlderThan(currentVersion, latestVersion)) {
      return UpdateCheckResult(
        hasUpdate: true,
        isForced: false,
        source: UpdateSource.supabase,
        currentVersion: currentVersion,
        latestVersion: latestVersion,
        storeUrl: storeUrl,
      );
    }

    return const UpdateCheckResult.noUpdate();
  }

  bool _isOlderThan(String current, String target) {
    if (current.isEmpty || target.isEmpty) return false;
    final c = _parseVersion(current);
    final t = _parseVersion(target);
    for (int i = 0; i < t.length; i++) {
      final ci = i < c.length ? c[i] : 0;
      if (ci < t[i]) return true;
      if (ci > t[i]) return false;
    }
    return false;
  }

  List<int> _parseVersion(String version) {
    return version
        .split('.')
        .map((s) => int.tryParse(s.trim()) ?? 0)
        .toList();
  }
}

// ─── 방식 1: Google Play In-App Update ──────────────────────────────────────

class InAppUpdateService implements UpdateCheckService {
  static const _storeUrl =
      'https://play.google.com/store/apps/details?id=com.kaman.sosigi';

  @override
  Future<UpdateCheckResult> check() async {
    if (!Platform.isAndroid) return const UpdateCheckResult.noUpdate();

    final packageInfo = await PackageInfo.fromPlatform();
    final info = await InAppUpdate.checkForUpdate();

    if (info.updateAvailability != UpdateAvailability.updateAvailable) {
      return const UpdateCheckResult.noUpdate();
    }

    return UpdateCheckResult(
      hasUpdate: true,
      isForced: false,
      source: UpdateSource.inAppUpdate,
      currentVersion: packageInfo.version,
      latestVersion: null,
      storeUrl: _storeUrl,
    );
  }

  Future<void> triggerUpdate() async {
    await InAppUpdate.performImmediateUpdate();
  }
}

// ─── 복합 체크: Supabase(강제) 우선, 이후 InAppUpdate(선택) ─────────────────

class CombinedUpdateService {
  final _supabase = SupabaseUpdateService();
  final _inApp = InAppUpdateService();

  Future<UpdateCheckResult> check() async {
    try {
      final supabaseResult = await _supabase.check();
      if (supabaseResult.hasUpdate && supabaseResult.isForced) {
        return supabaseResult;
      }
    } catch (e, st) {
      AppLogger.error('CombinedUpdateService', 'Supabase check failed', e, st);
    }

    try {
      return await _inApp.check();
    } catch (e, st) {
      AppLogger.error(
          'CombinedUpdateService', 'InAppUpdate check failed', e, st);
    }

    return const UpdateCheckResult.noUpdate();
  }

  Future<void> triggerInAppUpdate() async {
    await _inApp.triggerUpdate();
  }
}
