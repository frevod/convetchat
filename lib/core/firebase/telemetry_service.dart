import 'package:convetchat/core/platform_info.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talker_flutter/talker_flutter.dart';

class TelemetryService(final Talker _talker) {
  static const _consentKey = 'telemetry_consent';

  static final bool _supported = PlatformInfos.supportsFirebase;

  bool _consent = false;

  bool get hasConsent => _consent && _supported;

  FirebaseAnalytics? _analytics;
  FirebaseCrashlytics? _crashlytics;

  FirebaseAnalytics? get _analyticsOrNull {
    if (!_supported) return null;
    try {
      return _analytics ??= FirebaseAnalytics.instance;
    } catch (_) {
      return null;
    }
  }

  FirebaseCrashlytics? get _crashlyticsOrNull {
    if (!_supported) return null;
    try {
      return _crashlytics ??= FirebaseCrashlytics.instance;
    } catch (_) {
      return null;
    }
  }

  Future<void> init() async {
    if (!_supported) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _consent = prefs.getBool(_consentKey) ?? false;
      await _applyConsent();
    } catch (e) {
      _talker.error('[telemetry] init пропущен: $e');
    }
  }

  Future<void> _applyConsent() async {
    await _analyticsOrNull?.setAnalyticsCollectionEnabled(_consent);
    await _crashlyticsOrNull?.setCrashlyticsCollectionEnabled(_consent);
  }

  Future<void> setConsent(bool enabled) async {
    if (!_supported) return;
    if (_consent == enabled) return;
    _consent = enabled;
    try {
      await _applyConsent();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_consentKey, enabled);
    } catch (e) {
      _talker.error('[telemetry] setConsent($enabled) упал', e);
    }
  }

  void logEvent(String name, {Map<String, Object>? parameters}) {
    if (!hasConsent) return;
    try {
      _analyticsOrNull?.logEvent(name: name, parameters: parameters);
    } catch (e) {
      _talker.error('[telemetry] logEvent($name) упал', e);
    }
  }

  Future<void> setUserId(String? userId) async {
    if (!hasConsent) return;
    try {
      final analytics = _analyticsOrNull;
      final crashlytics = _crashlyticsOrNull;
      await analytics?.setUserId(id: userId);
      if (userId == null) {
        await crashlytics?.setUserIdentifier('');
      } else {
        await crashlytics?.setUserIdentifier(userId);
      }
    } catch (e) {
      _talker.error('[telemetry] setUserId упал', e);
    }
  }

  void logError(Object error, StackTrace stackTrace) {
    if (!_supported || !hasConsent) return;
    try {
      _crashlyticsOrNull?.recordError(error, stackTrace);
    } catch (e) {
      _talker.error('[telemetry] logError упал', e);
    }
  }
}
