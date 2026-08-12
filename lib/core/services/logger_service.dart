import 'package:flutter/foundation.dart';

class LoggerService {
  static void debug(String message, {String? tag}) {
    if (kDebugMode) {
      print('[DEBUG]${tag != null ? " [$tag]" : ""}: $message');
    }
  }

  static void info(String message, {String? tag}) {
    print('[INFO]${tag != null ? " [$tag]" : ""}: $message');
  }

  static void warning(String message, {String? tag}) {
    print('[WARNING]${tag != null ? " [$tag]" : ""}: $message');
  }

  static void error(String message, {dynamic error, StackTrace? stackTrace, String? tag}) {
    print('[ERROR]${tag != null ? " [$tag]" : ""}: $message');
    if (error != null) print('  Error: $error');
    if (stackTrace != null) print('  StackTrace: $stackTrace');
  }
}
