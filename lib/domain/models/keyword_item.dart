class KeywordNotificationTime {
  const KeywordNotificationTime({
    required this.hour,
    required this.minute,
  });

  static const KeywordNotificationTime defaultTime = KeywordNotificationTime(
    hour: 8,
    minute: 0,
  );

  final int hour;
  final int minute;

  int get totalMinutes => (hour * 60) + minute;

  String get storageValue =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  static KeywordNotificationTime fromStoredValue(Object? value) {
    if (value is! String) return defaultTime;

    final parts = value.trim().split(':');
    if (parts.length != 2) return defaultTime;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return defaultTime;
    if (hour < 0 || hour > 23) return defaultTime;
    if (minute < 0 || minute > 59) return defaultTime;

    return KeywordNotificationTime(hour: hour, minute: minute);
  }

  bool isReached(DateTime moment) {
    return ((moment.hour * 60) + moment.minute) >= totalMinutes;
  }
}

class KeywordItem {
  const KeywordItem({
    required this.id,
    required this.name,
    required this.notificationEnabled,
    this.notificationDeliveryTime = KeywordNotificationTime.defaultTime,
    this.lastNotifiedAt,
  });

  final String id;
  final String name;
  final bool notificationEnabled;
  final KeywordNotificationTime notificationDeliveryTime;
  final DateTime? lastNotifiedAt;

  KeywordItem copyWith({
    String? id,
    String? name,
    bool? notificationEnabled,
    KeywordNotificationTime? notificationDeliveryTime,
    DateTime? lastNotifiedAt,
    bool clearLastNotifiedAt = false,
  }) {
    return KeywordItem(
      id: id ?? this.id,
      name: name ?? this.name,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
      notificationDeliveryTime:
          notificationDeliveryTime ?? this.notificationDeliveryTime,
      lastNotifiedAt:
          clearLastNotifiedAt ? null : (lastNotifiedAt ?? this.lastNotifiedAt),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'notificationEnabled': notificationEnabled,
        'notificationDeliveryTime': notificationDeliveryTime.storageValue,
        if (lastNotifiedAt != null)
          'lastNotifiedAt': lastNotifiedAt!.toIso8601String(),
      };

  factory KeywordItem.fromJson(Map<String, dynamic> json) {
    return KeywordItem(
      id: json['id'] as String,
      name: json['name'] as String,
      notificationEnabled: json['notificationEnabled'] as bool? ?? true,
      notificationDeliveryTime: KeywordNotificationTime.fromStoredValue(
        json['notificationDeliveryTime'],
      ),
      lastNotifiedAt: json['lastNotifiedAt'] != null
          ? DateTime.tryParse(json['lastNotifiedAt'] as String)
          : null,
    );
  }
}
