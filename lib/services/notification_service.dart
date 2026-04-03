import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sosigi/domain/models/article.dart';
import 'package:sosigi/services/local_store_service.dart';
import 'package:url_launcher/url_launcher.dart';

class NotificationPermissionFlowResult {
  const NotificationPermissionFlowResult({
    required this.isGranted,
    required this.didRequestSystemPermission,
    required this.shouldOpenSettings,
    required this.deniedCount,
  });

  final bool isGranted;
  final bool didRequestSystemPermission;
  final bool shouldOpenSettings;
  final int deniedCount;
}

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();
  static const String _notificationIcon = 'ic_stat_sosigi';
  static const int _maxDeniedPermissionRequests = 3;
  static const MethodChannel _settingsChannel = MethodChannel(
    'sosigi/notification_settings',
  );

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final LocalStoreService _store = LocalStoreService();

  final ValueNotifier<String?> selectedKeywordFromNotification =
      ValueNotifier<String?>(null);

  Future<void>? _initializationFuture;

  static const AndroidNotificationChannel _keywordChannel =
      AndroidNotificationChannel(
        'keyword_news_channel',
        '키워드 뉴스 알림',
        description: '등록한 키워드 관련 새 뉴스 알림',
        importance: Importance.high,
      );

  Future<void> initialize() async {
    final existing = _initializationFuture;
    if (existing != null) {
      await existing;
      return;
    }

    final future = _initializeInternal().catchError((Object error) {
      _initializationFuture = null;
      throw error;
    });
    _initializationFuture = future;
    await future;
  }

  Future<void> _initializeInternal() async {
    const darwinSettings = DarwinInitializationSettings();
    const androidSettings = AndroidInitializationSettings(_notificationIcon);
    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _plugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse:
          _onBackgroundNotificationResponse,
    );

    final androidPlatform = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await androidPlatform?.createNotificationChannel(_keywordChannel);

    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp ?? false) {
      final payload = launchDetails?.notificationResponse?.payload;
      if (payload != null && payload.trim().isNotEmpty) {
        selectedKeywordFromNotification.value = payload.trim();
      }
    }
  }

  Future<NotificationPermissionFlowResult> ensurePermissionFlow() async {
    await initialize();

    if (await syncPermissionState()) {
      return const NotificationPermissionFlowResult(
        isGranted: true,
        didRequestSystemPermission: false,
        shouldOpenSettings: false,
        deniedCount: 0,
      );
    }

    final deniedCount = await _store.loadNotificationPermissionDeniedCount();
    if (deniedCount >= _maxDeniedPermissionRequests) {
      return NotificationPermissionFlowResult(
        isGranted: false,
        didRequestSystemPermission: false,
        shouldOpenSettings: true,
        deniedCount: deniedCount,
      );
    }

    final isGranted = await _requestNotificationPermission();
    if (isGranted) {
      await _store.resetNotificationPermissionDeniedCount();
      return const NotificationPermissionFlowResult(
        isGranted: true,
        didRequestSystemPermission: true,
        shouldOpenSettings: false,
        deniedCount: 0,
      );
    }

    final nextDeniedCount = deniedCount + 1;
    await _store.saveNotificationPermissionDeniedCount(nextDeniedCount);

    return NotificationPermissionFlowResult(
      isGranted: false,
      didRequestSystemPermission: true,
      shouldOpenSettings: nextDeniedCount >= _maxDeniedPermissionRequests,
      deniedCount: nextDeniedCount,
    );
  }

  Future<void> openNotificationSettings() async {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        try {
          await _settingsChannel.invokeMethod<void>('open');
          return;
        } on MissingPluginException {
          // Fall back to the platform-agnostic settings URL below.
        } on PlatformException {
          // Fall back to the platform-agnostic settings URL below.
        }
        break;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        break;
      default:
        return;
    }

    final settingsUri = Uri.parse('app-settings:');
    if (await canLaunchUrl(settingsUri)) {
      await launchUrl(settingsUri);
    }
  }

  Future<void> showKeywordSummary({
    required String keyword,
    required List<Article> articles,
  }) async {
    if (articles.isEmpty) return;
    if (!await canShowNotifications()) return;

    final count = articles.length;
    final latest = articles.first.title;

    const androidDetails = AndroidNotificationDetails(
      'keyword_news_channel',
      '키워드 뉴스 알림',
      channelDescription: '등록한 키워드 관련 새 뉴스 알림',
      importance: Importance.high,
      priority: Priority.high,
      ticker: '키워드 뉴스',
      icon: _notificationIcon,
    );

    const details = NotificationDetails(android: androidDetails);

    await _plugin.show(
      keyword.hashCode & 0x7fffffff,
      '$keyword 뉴스 발견',
      count == 1 ? latest : '$count건의 새 뉴스가 있습니다.',
      details,
      payload: keyword,
    );
  }

  void consumeSelectedKeyword() {
    selectedKeywordFromNotification.value = null;
  }

  void _onNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null && payload.trim().isNotEmpty) {
      selectedKeywordFromNotification.value = payload.trim();
    }
  }

  Future<bool> canShowNotifications() async {
    await initialize();
    return _hasNotificationPermission();
  }

  Future<bool> syncPermissionState() async {
    await initialize();
    final isGranted = await _hasNotificationPermission();
    if (isGranted) {
      await _store.resetNotificationPermissionDeniedCount();
    }
    return isGranted;
  }

  Future<bool> _hasNotificationPermission() async {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        final androidPlatform = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        return await androidPlatform?.areNotificationsEnabled() ?? false;
      case TargetPlatform.iOS:
        final iosPlatform = _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
        return (await iosPlatform?.checkPermissions())?.isEnabled ?? false;
      case TargetPlatform.macOS:
        final macPlatform = _plugin.resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin>();
        return (await macPlatform?.checkPermissions())?.isEnabled ?? false;
      default:
        return true;
    }
  }

  Future<bool> _requestNotificationPermission() async {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        final androidPlatform = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        return await androidPlatform?.requestNotificationsPermission() ?? false;
      case TargetPlatform.iOS:
        final iosPlatform = _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
        return await iosPlatform?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ) ??
            false;
      case TargetPlatform.macOS:
        final macPlatform = _plugin.resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin>();
        return await macPlatform?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ) ??
            false;
      default:
        return false;
    }
  }
}

@pragma('vm:entry-point')
void _onBackgroundNotificationResponse(NotificationResponse response) {
  final payload = response.payload;
  if (payload != null && payload.trim().isNotEmpty) {
    NotificationService.instance.selectedKeywordFromNotification.value =
        payload.trim();
  }
}
