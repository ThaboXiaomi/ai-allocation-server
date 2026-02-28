import 'package:flutter/foundation.dart';

class Logger {
  static LogMode _logMode = LogMode.debug;

  static void init(LogMode mode) {
    _logMode = mode;
  }

  static void log(dynamic data, {StackTrace? stackTrace}) {
    if (_logMode == LogMode.debug) {
      debugPrint('LOG: $data');
      if (stackTrace != null) {
        debugPrint('$stackTrace');
      }
    }
  }
}

enum LogMode { debug, live }
