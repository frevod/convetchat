import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/firebase/telemetry_service.dart';
import 'package:talker_flutter/talker_flutter.dart';

final class CrashlyticsTalkerObserver() extends TalkerObserver {
  bool _forwarding = false;

  TelemetryService? _telemetry;

  @override
  void onLog(TalkerData log) {
    if (log.logLevel == LogLevel.error &&
        (log.error != null || log.exception != null)) {
      _forward(log.error ?? log.exception, log.stackTrace);
    }
  }

  @override
  void onError(TalkerError err) {
    _forward(err.error, err.stackTrace);
  }

  @override
  void onException(TalkerException err) {
    _forward(err.exception, err.stackTrace);
  }

  void _forward(Object? error, StackTrace? stackTrace) {
    if (error == null || _forwarding) return;
    _forwarding = true;
    try {
      final telemetry = _telemetry ??= getIt.isRegistered<TelemetryService>()
          ? getIt<TelemetryService>()
          : null;
      if (telemetry == null) return;
      telemetry.logError(error, stackTrace ?? StackTrace.current);
    } finally {
      _forwarding = false;
    }
  }
}
