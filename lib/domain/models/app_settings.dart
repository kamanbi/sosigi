enum SyncIntervalOption {
  min15(15),
  min30(30),
  hour1(60);

  const SyncIntervalOption(this.minutes);

  final int minutes;

  Duration get duration => Duration(minutes: minutes);

  String get label => minutes < 60 ? '$minutes분' : '${minutes ~/ 60}시간';

  String get storageValue => minutes.toString();

  static SyncIntervalOption fromStoredValue(Object? value) {
    if (value is String) {
      final normalized = value.trim();
      final parsed = int.tryParse(normalized);
      if (parsed != null) {
        return _fromMinutes(parsed);
      }

      return switch (normalized) {
        'min15' => SyncIntervalOption.min15,
        'min30' => SyncIntervalOption.min30,
        'hour1' => SyncIntervalOption.hour1,
        'min5' => SyncIntervalOption.min15,
        _ => SyncIntervalOption.hour1,
      };
    }

    if (value is int) {
      if (value >= 0 && value <= 2) {
        return switch (value) {
          0 => SyncIntervalOption.min15,
          1 => SyncIntervalOption.min30,
          _ => SyncIntervalOption.hour1,
        };
      }

      return _fromMinutes(value);
    }

    return SyncIntervalOption.hour1;
  }

  static SyncIntervalOption _fromMinutes(int value) {
    return switch (value) {
      5 => SyncIntervalOption.min15,
      15 => SyncIntervalOption.min15,
      30 => SyncIntervalOption.min30,
      60 => SyncIntervalOption.hour1,
      _ => SyncIntervalOption.hour1,
    };
  }
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

  const AppSettings({
    required this.wifiOnly,
    required this.suppressMobileDataWarning,
    required this.syncInterval,
    required this.retentionOption,
  });

  factory AppSettings.initial() {
    return const AppSettings(
      wifiOnly: true,
      suppressMobileDataWarning: false,
      syncInterval: SyncIntervalOption.hour1,
      retentionOption: RetentionOption.hour120,
    );
  }

  AppSettings copyWith({
    bool? wifiOnly,
    bool? suppressMobileDataWarning,
    SyncIntervalOption? syncInterval,
    RetentionOption? retentionOption,
  }) {
    return AppSettings(
      wifiOnly: wifiOnly ?? this.wifiOnly,
      suppressMobileDataWarning:
          suppressMobileDataWarning ?? this.suppressMobileDataWarning,
      syncInterval: syncInterval ?? this.syncInterval,
      retentionOption: retentionOption ?? this.retentionOption,
    );
  }
}
