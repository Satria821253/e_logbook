import 'package:flutter/foundation.dart';

/// Crash reporter service
/// TODO: Integrate with Firebase Crashlytics or Sentry
/// Add to pubspec.yaml: firebase_crashlytics: ^3.4.0 or sentry_flutter: ^7.0.0
class CrashReporter {
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    // Setup error handlers
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      recordError(details.exception, details.stack, fatal: true);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      recordError(error, stack, fatal: true);
      return true;
    };

    _initialized = true;
    debugPrint('🔍 Crash reporter initialized');
  }

  static void recordError(
    dynamic exception,
    StackTrace? stack, {
    bool fatal = false,
    Map<String, dynamic>? context,
  }) {
    if (kDebugMode) {
      debugPrint('❌ Error recorded: $exception');
      if (stack != null) debugPrint('Stack: $stack');
      if (context != null) debugPrint('Context: $context');
    }

    // TODO: Send to crash reporting service
    // FirebaseCrashlytics.instance.recordError(exception, stack, fatal: fatal);
    // or
    // Sentry.captureException(exception, stackTrace: stack);
  }

  static void log(String message) {
    if (kDebugMode) {
      debugPrint('📝 Log: $message');
    }
    // TODO: Send to logging service
    // FirebaseCrashlytics.instance.log(message);
  }

  static void setUserIdentifier(String userId) {
    if (kDebugMode) {
      debugPrint('👤 User ID set: $userId');
    }
    // TODO: Set user identifier in crash reporting
    // FirebaseCrashlytics.instance.setUserIdentifier(userId);
  }

  static void setCustomKey(String key, dynamic value) {
    if (kDebugMode) {
      debugPrint('🔑 Custom key: $key = $value');
    }
    // TODO: Set custom key in crash reporting
    // FirebaseCrashlytics.instance.setCustomKey(key, value);
  }
}
