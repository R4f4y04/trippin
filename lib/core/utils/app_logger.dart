import 'package:flutter/foundation.dart';

class AppLogger {
  static void info(String message) => debugPrint('ℹ️ [INFO]: $message');
  static void warning(String message) => debugPrint('⚠️ [WARN]: $message');
  static void error(String message, [dynamic error, StackTrace? stack]) {
    debugPrint('🔴 [ERROR]: $message');
    if (error != null) debugPrint('Error: $error');
    if (stack != null) debugPrint('Stack: $stack');
  }
}
