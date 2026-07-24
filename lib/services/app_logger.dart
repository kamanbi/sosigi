import 'package:flutter/foundation.dart';

class AppLogger {
  AppLogger._();

  static final ValueNotifier<List<String>> logs = ValueNotifier<List<String>>(
    const [],
  );

  static void info(String tag, String message) {
    final now = DateTime.now();
    final timestamp =
        '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}';
    final line = '[$timestamp] [INFO] [$tag] $message';
    debugPrint(line);

    final next = List<String>.from(logs.value)..add(line);
    if (next.length > 200) {
      next.removeRange(0, next.length - 200);
    }
    logs.value = List.unmodifiable(next);
  }

  static void warn(String tag, String message) {
    // Intentionally skipped. Only error logs are retained.
  }

  static void error(String tag, String message, [Object? error, StackTrace? st]) {
    final suffix = error == null ? '' : ' | error=$error';
    final now = DateTime.now();
    final timestamp =
        '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}';

    final line = '[$timestamp] [ERROR] [$tag] $message$suffix';
    debugPrint(line);

    final next = List<String>.from(logs.value)..add(line);
    if (next.length > 200) {
      next.removeRange(0, next.length - 200);
    }
    logs.value = List.unmodifiable(next);

    if (st != null) {
      debugPrint(st.toString());
    }
  }

  static void clear() {
    logs.value = const [];
  }
}
