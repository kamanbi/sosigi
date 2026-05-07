import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sosigi/data/default_news_sources.dart';
import 'package:sosigi/domain/models/app_settings.dart';
import 'package:sosigi/domain/models/article.dart';
import 'package:sosigi/domain/models/keyword_item.dart';
import 'package:sosigi/domain/models/news_source.dart';

class LocalStoreService {
  static const _appBoxName = 'sosigi_app_box';
  static const _migrationKey = 'migration_v1_completed';

  static const _settingsWifiOnly = 'settings_wifi_only';
  static const _settingsWarning = 'settings_warning';
  static const _settingsSync = 'settings_sync';
  static const _settingsRetention = 'settings_retention';
  static const _settingsQuietHoursStart = 'settings_quiet_hours_start';
  static const _settingsQuietHoursEnd = 'settings_quiet_hours_end';

  static const _keywords = 'keywords';
  static const _sources = 'sources';
  static const _articles = 'articles';
  static const _lastSync = 'last_sync';

  static const _readArticleIds = 'read_article_ids';
  static const _bookmarkedArticleIds = 'bookmarked_article_ids';
  static const _notifiedArticleKeys = 'notified_article_keys';
  static const _notificationPermissionDeniedCount =
      'notification_permission_denied_count';
  static const _notificationPromptSuppressed =
      'notification_prompt_suppressed';
  static const _backgroundPromptSuppressed =
      'background_prompt_suppressed';
  static const _lastBackgroundSyncResult = 'last_background_sync_result';
  static const _refreshLease = 'refresh_lease';

  static Box<dynamic>? _box;
  static Future<void>? _initializationFuture;

  static Future<void> initialize() async {
    final existing = _initializationFuture;
    if (existing != null) {
      await existing;
      return;
    }

    final future = _initializeInternal();
    _initializationFuture = future;
    await future;
  }

  static Future<void> _initializeInternal() async {
    await Hive.initFlutter();
    _box ??= await Hive.openBox<dynamic>(_appBoxName);
    await _migrateFromSharedPreferencesIfNeeded();
  }

  static Future<void> _migrateFromSharedPreferencesIfNeeded() async {
    final box = _requireBox();
    final migrated = box.get(_migrationKey) as bool? ?? false;
    if (migrated) return;

    final prefs = await SharedPreferences.getInstance();

    await _copyIfPresent<bool>(prefs, box, _settingsWifiOnly, prefs.getBool);
    await _copyIfPresent<bool>(prefs, box, _settingsWarning, prefs.getBool);
    await _copyIfPresent<int>(prefs, box, _settingsSync, prefs.getInt);
    await _copyIfPresent<int>(
      prefs,
      box,
      _settingsRetention,
      prefs.getInt,
    );
    await _copyIfPresent<String>(
      prefs,
      box,
      _settingsQuietHoursStart,
      prefs.getString,
    );
    await _copyIfPresent<String>(
      prefs,
      box,
      _settingsQuietHoursEnd,
      prefs.getString,
    );
    await _copyIfPresent<String>(prefs, box, _keywords, prefs.getString);
    await _copyIfPresent<String>(prefs, box, _sources, prefs.getString);
    await _copyIfPresent<String>(prefs, box, _articles, prefs.getString);
    await _copyIfPresent<String>(prefs, box, _lastSync, prefs.getString);
    await _copyIfPresent<List<String>>(
      prefs,
      box,
      _readArticleIds,
      prefs.getStringList,
    );
    await _copyIfPresent<List<String>>(
      prefs,
      box,
      _bookmarkedArticleIds,
      prefs.getStringList,
    );
    await _copyIfPresent<List<String>>(
      prefs,
      box,
      _notifiedArticleKeys,
      prefs.getStringList,
    );
    await _copyIfPresent<int>(
      prefs,
      box,
      _notificationPermissionDeniedCount,
      prefs.getInt,
    );

    await box.put(_migrationKey, true);
  }

  static Future<void> _copyIfPresent<T>(
    SharedPreferences prefs,
    Box<dynamic> box,
    String key,
    T? Function(String key) reader,
  ) async {
    final value = reader(key);
    if (value != null && !box.containsKey(key)) {
      await box.put(key, value);
    }
  }

  static Box<dynamic> _requireBox() {
    final box = _box;
    if (box == null) {
      throw StateError('LocalStoreService.initialize() must be called first.');
    }
    return box;
  }

  Future<Box<dynamic>> _getBox() async {
    await initialize();
    return _requireBox();
  }

  Future<AppSettings> loadSettings() async {
    final box = await _getBox();
    final syncRaw = box.get(_settingsSync);
    final retentionRaw = box.get(_settingsRetention);
    final quietHoursStartRaw = box.get(_settingsQuietHoursStart);
    final quietHoursEndRaw = box.get(_settingsQuietHoursEnd);

    return AppSettings(
      wifiOnly: box.get(_settingsWifiOnly) as bool? ?? true,
      suppressMobileDataWarning: box.get(_settingsWarning) as bool? ?? false,
      syncInterval: SyncIntervalOption.fromStoredValue(syncRaw),
      retentionOption: RetentionOption.fromStoredValue(retentionRaw),
      notificationQuietHours: NotificationQuietHours(
        start: NotificationQuietTime.fromStoredValue(
          quietHoursStartRaw,
          fallback: NotificationQuietTime.defaultStart,
        ),
        end: NotificationQuietTime.fromStoredValue(
          quietHoursEndRaw,
          fallback: NotificationQuietTime.defaultEnd,
        ),
      ),
    );
  }

  Future<void> saveSettings(AppSettings settings) async {
    final box = await _getBox();
    await box.put(_settingsWifiOnly, settings.wifiOnly);
    await box.put(_settingsWarning, settings.suppressMobileDataWarning);
    await box.put(_settingsSync, settings.syncInterval.storageValue);
    await box.put(_settingsRetention, settings.retentionOption.storageValue);
    await box.put(
      _settingsQuietHoursStart,
      settings.notificationQuietHours.start.storageValue,
    );
    await box.put(
      _settingsQuietHoursEnd,
      settings.notificationQuietHours.end.storageValue,
    );
  }

  Future<List<KeywordItem>> loadKeywords() async {
    final box = await _getBox();
    final raw = box.get(_keywords) as String?;
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => KeywordItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> saveKeywords(List<KeywordItem> keywords) async {
    final box = await _getBox();
    final raw = jsonEncode(keywords.map((e) => e.toJson()).toList());
    await box.put(_keywords, raw);
  }

  Future<List<NewsSource>> loadSources() async {
    final box = await _getBox();
    final raw = box.get(_sources) as String?;
    if (raw == null || raw.isEmpty) return runtimeDefaultNewsSources;
    final decoded = jsonDecode(raw) as List<dynamic>;
    final savedSources = decoded
        .map((e) => NewsSource.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    return _reconcileSourcesWithRuntimeDefaults(savedSources);
  }

  Future<void> saveSources(List<NewsSource> sources) async {
    final box = await _getBox();
    final raw = jsonEncode(sources.map((e) => e.toJson()).toList());
    await box.put(_sources, raw);
  }

  Future<List<Article>> loadArticles() async {
    final box = await _getBox();
    final raw = box.get(_articles) as String?;
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => Article.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> saveArticles(List<Article> articles) async {
    final box = await _getBox();
    final raw = jsonEncode(articles.map((e) => e.toJson()).toList());
    await box.put(_articles, raw);
  }

  Future<DateTime?> loadLastSync() async {
    final box = await _getBox();
    final raw = box.get(_lastSync) as String?;
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> saveLastSync(DateTime value) async {
    final box = await _getBox();
    await box.put(_lastSync, value.toIso8601String());
  }

  Future<Set<String>> loadReadArticleIds() async {
    final box = await _getBox();
    final values = box.get(_readArticleIds);
    if (values is List) {
      return values.map((value) => value.toString()).toSet();
    }
    return <String>{};
  }

  Future<void> saveReadArticleIds(Set<String> ids) async {
    final box = await _getBox();
    await box.put(_readArticleIds, ids.toList());
  }

  Future<Set<String>> loadBookmarkedArticleIds() async {
    final box = await _getBox();
    final values = box.get(_bookmarkedArticleIds);
    if (values is List) {
      return values.map((value) => value.toString()).toSet();
    }
    return <String>{};
  }

  Future<void> saveBookmarkedArticleIds(Set<String> ids) async {
    final box = await _getBox();
    await box.put(_bookmarkedArticleIds, ids.toList());
  }

  Future<Set<String>> loadNotifiedArticleKeys() async {
    final box = await _getBox();
    final values = box.get(_notifiedArticleKeys);
    if (values is List) {
      return values.map((value) => value.toString()).toSet();
    }
    return <String>{};
  }

  Future<void> saveNotifiedArticleKeys(Set<String> keys) async {
    final box = await _getBox();
    await box.put(_notifiedArticleKeys, keys.toList());
  }

  Future<int> loadNotificationPermissionDeniedCount() async {
    final box = await _getBox();
    return box.get(_notificationPermissionDeniedCount) as int? ?? 0;
  }

  Future<void> saveNotificationPermissionDeniedCount(int count) async {
    final box = await _getBox();
    await box.put(_notificationPermissionDeniedCount, count);
  }

  Future<void> resetNotificationPermissionDeniedCount() async {
    await saveNotificationPermissionDeniedCount(0);
  }

  Future<bool> loadNotificationPromptSuppressed() async {
    final box = await _getBox();
    return box.get(_notificationPromptSuppressed) as bool? ?? false;
  }

  Future<void> saveNotificationPromptSuppressed(bool value) async {
    final box = await _getBox();
    await box.put(_notificationPromptSuppressed, value);
  }

  Future<bool> loadBackgroundPromptSuppressed() async {
    final box = await _getBox();
    return box.get(_backgroundPromptSuppressed) as bool? ?? false;
  }

  Future<void> saveBackgroundPromptSuppressed(bool value) async {
    final box = await _getBox();
    await box.put(_backgroundPromptSuppressed, value);
  }

  Future<Map<String, dynamic>?> loadLastBackgroundSyncResult() async {
    final box = await _getBox();
    final raw = box.get(_lastBackgroundSyncResult) as String?;
    if (raw == null || raw.isEmpty) return null;
    return Map<String, dynamic>.from(jsonDecode(raw) as Map);
  }

  Future<void> saveLastBackgroundSyncResult(
    Map<String, dynamic> data,
  ) async {
    final box = await _getBox();
    await box.put(_lastBackgroundSyncResult, jsonEncode(data));
  }

  Future<bool> tryAcquireRefreshLease({
    required String owner,
    required Duration staleAfter,
  }) async {
    final box = await _getBox();
    final raw = box.get(_refreshLease) as String?;
    final now = DateTime.now().toUtc();

    if (raw != null && raw.isNotEmpty) {
      final decoded = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      final activeOwner = decoded['owner'] as String?;
      final acquiredAtRaw = decoded['acquiredAt'] as String?;
      final acquiredAt = acquiredAtRaw == null
          ? null
          : DateTime.tryParse(acquiredAtRaw)?.toUtc();

      if (activeOwner != null &&
          acquiredAt != null &&
          now.difference(acquiredAt) < staleAfter) {
        return false;
      }
    }

    await box.put(
      _refreshLease,
      jsonEncode({
        'owner': owner,
        'acquiredAt': now.toIso8601String(),
      }),
    );
    return true;
  }

  Future<void> releaseRefreshLease({
    required String owner,
  }) async {
    final box = await _getBox();
    final raw = box.get(_refreshLease) as String?;
    if (raw == null || raw.isEmpty) return;

    final decoded = Map<String, dynamic>.from(jsonDecode(raw) as Map);
    final activeOwner = decoded['owner'] as String?;
    if (activeOwner != owner) return;

    await box.delete(_refreshLease);
  }

  List<NewsSource> _reconcileSourcesWithRuntimeDefaults(
    List<NewsSource> savedSources,
  ) {
    final runtimeSourcesById = {
      for (final source in runtimeDefaultNewsSources) source.id: source,
    };

    final reconciledSources = savedSources.map((savedSource) {
      final runtimeSource = runtimeSourcesById[savedSource.id];
      if (runtimeSource == null) {
        return savedSource;
      }

      return runtimeSource.copyWith(enabled: savedSource.enabled);
    }).toList();

    final reconciledIds = reconciledSources.map((source) => source.id).toSet();
    final missingRuntimeSources = runtimeDefaultNewsSources.where(
      (source) => !reconciledIds.contains(source.id),
    );

    return [
      ...reconciledSources,
      ...missingRuntimeSources,
    ];
  }
}
