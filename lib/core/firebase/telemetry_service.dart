import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talker_flutter/talker_flutter.dart';

class TelemetryService(final Talker _talker) {
  static const _consentKey = 'telemetry_consent';

  bool _consent = false;

  bool get hasConsent => _consent;

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _consent = prefs.getBool(_consentKey) ?? false;
      await _applyConsent();
    } catch (e) {
      _talker.error('[telemetry] init пропущен: $e');
    }
  }

  Future<void> _applyConsent() async {
    await _analytics.setAnalyticsCollectionEnabled(_consent);
    await _crashlytics.setCrashlyticsCollectionEnabled(_consent);
  }

  Future<void> setConsent(bool enabled) async {
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
      _analytics.logEvent(name: name, parameters: parameters);
    } catch (e) {
      _talker.error('[telemetry] logEvent($name) упал', e);
    }
  }

  Future<void> setUserId(String? userId) async {
    if (!hasConsent) return;
    try {
      await _analytics.setUserId(id: userId);
      if (userId == null) {
        await _crashlytics.setUserIdentifier('');
      } else {
        await _crashlytics.setUserIdentifier(userId);
      }
    } catch (e) {
      _talker.error('[telemetry] setUserId упал', e);
    }
  }

  void logError(Object error, StackTrace stackTrace) {
    if (!hasConsent) return;
    try {
      _crashlytics.recordError(error, stackTrace);
    } catch (e) {
      _talker.error('[telemetry] logError упал', e);
    }
  }
}
