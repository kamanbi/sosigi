import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sosigi/domain/models/app_settings.dart';
import 'package:sosigi/services/local_store_service.dart';

final localStoreProvider = Provider<LocalStoreService>((ref) {
  return LocalStoreService();
});

final appSettingsProvider =
    StateNotifierProvider<AppSettingsNotifier, AppSettings>((ref) {
  return AppSettingsNotifier(ref.read(localStoreProvider));
});

class AppSettingsNotifier extends StateNotifier<AppSettings> {
  AppSettingsNotifier(this._store) : super(AppSettings.initial());

  final LocalStoreService _store;
  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    state = await _store.loadSettings();
    _loaded = true;
  }

  Future<void> setWifiOnly(bool value) async {
    final next = state.copyWith(wifiOnly: value);
    state = next;
    await _store.saveSettings(next);
  }

  Future<void> setSuppressMobileDataWarning(bool value) async {
    final next = state.copyWith(suppressMobileDataWarning: value);
    state = next;
    await _store.saveSettings(next);
  }

  Future<void> setSyncInterval(SyncIntervalOption value) async {
    final next = state.copyWith(syncInterval: value);
    state = next;
    await _store.saveSettings(next);
  }

  Future<void> setRetentionOption(RetentionOption value) async {
    final next = state.copyWith(retentionOption: value);
    state = next;
    await _store.saveSettings(next);
  }

  Future<void> setNotificationQuietHoursStart(
    NotificationQuietTime value,
  ) async {
    final next = state.copyWith(
      notificationQuietHours: NotificationQuietHours(
        start: value,
        end: state.notificationQuietHours.end,
      ),
    );
    state = next;
    await _store.saveSettings(next);
  }

  Future<void> setNotificationQuietHoursEnd(
    NotificationQuietTime value,
  ) async {
    final next = state.copyWith(
      notificationQuietHours: NotificationQuietHours(
        start: state.notificationQuietHours.start,
        end: value,
      ),
    );
    state = next;
    await _store.saveSettings(next);
  }
}
