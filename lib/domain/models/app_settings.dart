class NotificationQuietTime {
  const NotificationQuietTime({
    required this.hour,
    required this.minute,
  });

  final int hour;
  final int minute;

  static const NotificationQuietTime defaultStart = NotificationQuietTime(
    hour: 18,
    minute: 0,
  );
  static const NotificationQuietTime defaultEnd = NotificationQuietTime(
    hour: 7,
    minute: 0,
  );

  int get totalMinutes => (hour * 60) + minute;

  String get storageValue =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  static NotificationQuietTime fromStoredValue(
    Object? value, {
    required NotificationQuietTime fallback,
  }) {
    if (value is! String) return fallback;

    final normalized = value.trim();
    final parts = normalized.split(':');
    if (parts.length != 2) return fallback;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return fallback;
    if (hour < 0 || hour > 23) return fallback;
    if (minute < 0 || minute > 59) return fallback;

    return NotificationQuietTime(hour: hour, minute: minute);
  }
}

class NotificationQuietHours {
  const NotificationQuietHours({
    required this.start,
    required this.end,
  });

  final NotificationQuietTime start;
  final NotificationQuietTime end;

  factory NotificationQuietHours.initial() {
    return const NotificationQuietHours(
      start: NotificationQuietTime.defaultStart,
      end: NotificationQuietTime.defaultEnd,
    );
  }

  bool contains(DateTime moment) {
    final currentMinutes = (moment.hour * 60) + moment.minute;
    final startMinutes = start.totalMinutes;
    final endMinutes = end.totalMinutes;

    if (startMinutes == endMinutes) {
      return false;
    }

    if (startMinutes < endMinutes) {
      return currentMinutes >= startMinutes && currentMinutes < endMinutes;
    }

    return currentMinutes >= startMinutes || currentMinutes < endMinutes;
  }
}

class SyncIntervalOption {
  const SyncIntervalOption._(this.minutes);

  static const int minimumMinutes = 30;
  static const int maximumMinutes = 24 * 60;
  static const int stepMinutes = 30;
  static const int defaultMinutes = 4 * 60;

  static const SyncIntervalOption min30 = SyncIntervalOption._(30);
  static const SyncIntervalOption hour1 = SyncIntervalOption._(60);

  final int minutes;

  Duration get duration => Duration(minutes: minutes);

  int get hourValue => minutes ~/ 60;

  int get minuteValue => minutes % 60;

  String get label {
    if (minutes < 60) {
      return '$minutes분';
    }

    final hours = hourValue;
    final remainingMinutes = minuteValue;
    if (remainingMinutes == 0) {
      return '$hours시간';
    }

    return '$hours시간 ${remainingMinutes.toString().padLeft(2, '0')}분';
  }

  String get storageValue => minutes.toString();

  static SyncIntervalOption initial() =>
      const SyncIntervalOption._(defaultMinutes);

  static SyncIntervalOption fromStoredValue(Object? value) {
    if (value is String) {
      final normalized = value.trim();
      final parsed = int.tryParse(normalized);
      if (parsed != null) {
        return fromMinutes(parsed);
      }

      return switch (normalized) {
        'min15' => min30,
        'min30' => min30,
        'hour1' => hour1,
        'min5' => min30,
        _ => initial(),
      };
    }

    if (value is int) {
      if (value >= 0 && value <= 2) {
        return switch (value) {
          0 => min30,
          1 => min30,
          _ => hour1,
        };
      }

      return fromMinutes(value);
    }

    return initial();
  }

  static SyncIntervalOption fromMinutes(int value) {
    final normalizedMinutes = _normalizeMinutes(value);
    return SyncIntervalOption._(normalizedMinutes);
  }

  static SyncIntervalOption fromWheelValues({
    required int hour,
    required int minute,
  }) {
    final totalMinutes = (hour * 60) + minute;
    if (totalMinutes <= 0) {
      return min30;
    }
    return fromMinutes(totalMinutes);
  }

  static bool isSelectable({
    required int hour,
    required int minute,
  }) {
    final totalMinutes = (hour * 60) + minute;
    if (totalMinutes < minimumMinutes) return false;
    if (totalMinutes > maximumMinutes) return false;
    return totalMinutes % stepMinutes == 0;
  }

  static int _normalizeMinutes(int value) {
    if (value <= 0) return defaultMinutes;

    var normalizedValue = value;
    if (normalizedValue < minimumMinutes) {
      normalizedValue = minimumMinutes;
    }

    if (normalizedValue > maximumMinutes) {
      normalizedValue = maximumMinutes;
    }

    final remainder = normalizedValue % stepMinutes;
    if (remainder == 0) {
      return normalizedValue;
    }

    final roundedUp = normalizedValue + (stepMinutes - remainder);
    return roundedUp > maximumMinutes ? maximumMinutes : roundedUp;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SyncIntervalOption && other.minutes == minutes;
  }

  @override
  int get hashCode => minutes.hashCode;
}

enum RetentionOption {
  hour72(72),
  hour96(96),
  hour120(120);

  const RetentionOption(this.hours);

  final int hours;

  Duration get duration => Duration(hours: hours);

  String get label => '${hours}h';

  String get storageValue => hours.toString();

  static RetentionOption fromStoredValue(Object? value) {
    if (value is String) {
      final normalized = value.trim();
      final parsed = int.tryParse(normalized);
      if (parsed != null) {
        return _fromInt(parsed);
      }

      return switch (normalized) {
        'hour72' => RetentionOption.hour72,
        'hour96' => RetentionOption.hour96,
        'hour120' => RetentionOption.hour120,
        _ => RetentionOption.hour120,
      };
    }

    if (value is int) {
      return _fromInt(value);
    }

    return RetentionOption.hour120;
  }

  static RetentionOption _fromInt(int value) {
    if (value >= 0 && value < values.length) {
      return values[value];
    }

    return switch (value) {
      24 => RetentionOption.hour72,
      48 => RetentionOption.hour96,
      72 => RetentionOption.hour72,
      96 => RetentionOption.hour96,
      120 => RetentionOption.hour120,
      _ => RetentionOption.hour120,
    };
  }
}

class AppSettings {
  final bool wifiOnly;
  final bool suppressMobileDataWarning;
  final SyncIntervalOption syncInterval;
  final RetentionOption retentionOption;
  final NotificationQuietHours notificationQuietHours;

  const AppSettings({
    required this.wifiOnly,
    required this.suppressMobileDataWarning,
    required this.syncInterval,
    required this.retentionOption,
    required this.notificationQuietHours,
  });

  factory AppSettings.initial() {
    return AppSettings(
      wifiOnly: true,
      suppressMobileDataWarning: false,
      syncInterval: SyncIntervalOption.initial(),
      retentionOption: RetentionOption.hour120,
      notificationQuietHours: NotificationQuietHours.initial(),
    );
  }

  AppSettings copyWith({
    bool? wifiOnly,
    bool? suppressMobileDataWarning,
    SyncIntervalOption? syncInterval,
    RetentionOption? retentionOption,
    NotificationQuietHours? notificationQuietHours,
  }) {
    return AppSettings(
      wifiOnly: wifiOnly ?? this.wifiOnly,
      suppressMobileDataWarning:
          suppressMobileDataWarning ?? this.suppressMobileDataWarning,
      syncInterval: syncInterval ?? this.syncInterval,
      retentionOption: retentionOption ?? this.retentionOption,
      notificationQuietHours:
          notificationQuietHours ?? this.notificationQuietHours,
    );
  }
}
