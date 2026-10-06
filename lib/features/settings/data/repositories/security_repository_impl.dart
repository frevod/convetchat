import 'dart:convert';
import 'dart:math';

import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/features/settings/domain/repositories/security_repository.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';
import 'package:matrix/matrix.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talker_flutter/talker_flutter.dart';

class SecurityRepositoryImpl({LocalAuthentication? auth})
    implements SecurityRepository {
  this : _auth = auth ?? LocalAuthentication();

  static const _appLockKey = 'security_app_lock_enabled';
  static const _biometricsKey = 'security_biometrics_enabled';
  static const _shareKeysWithKey = 'security_share_keys_with';

  static const _pinHashStorageKey = 'security_app_pin_hash';
  static const _legacyPinStorageKey = 'security_app_pin';

  static const _secureStorage = FlutterSecureStorage();

  final LocalAuthentication _auth;

  bool? _appLockCache;
  bool? _biometricsCache;

  Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

  static String _randomSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64Url.encode(bytes);
  }

  static String _hash(String salt, String pin) =>
      sha256.convert(utf8.encode('$salt:$pin')).toString();

  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }

  @override
  Future<bool> isAppLockEnabled() async {
    final cached = _appLockCache;
    if (cached != null) return cached;
    try {
      final enabled = (await _prefs()).getBool(_appLockKey) ?? false;
      if (enabled && !await hasPin()) {
        _appLockCache = false;
        return false;
      }
      _appLockCache = enabled;
      return enabled;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> setAppLockEnabled(bool enabled) async {
    _appLockCache = enabled;
    try {
      await (await _prefs()).setBool(_appLockKey, enabled);
    } catch (e, s) {
      getIt<Talker>().error('[security] save app lock failed', e, s);
    }
    if (!enabled) {
      await setBiometricsEnabled(false);
    }
  }

  @override
  Future<bool> hasPin() async {
    try {
      final hashed = await _secureStorage.read(key: _pinHashStorageKey);
      if (hashed != null && hashed.contains(':')) return true;
      final legacy = await _secureStorage.read(key: _legacyPinStorageKey);
      return legacy != null && legacy.length == 4;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> setPin(String pin) async {
    if (!RegExp(r'^\d{4}$').hasMatch(pin)) {
      throw ArgumentError('PIN должен состоять из 4 цифр');
    }
    try {
      final salt = _randomSalt();
      await _secureStorage.write(
        key: _pinHashStorageKey,
        value: '$salt:${_hash(salt, pin)}',
      );
      await _secureStorage.delete(key: _legacyPinStorageKey);
    } catch (e, s) {
      getIt<Talker>().error('[security] save PIN failed', e, s);
      rethrow;
    }
  }

  @override
  Future<bool> verifyPin(String pin) async {
    try {
      final stored = await _secureStorage.read(key: _pinHashStorageKey);
      if (stored != null && stored.contains(':')) {
        final separator = stored.indexOf(':');
        final salt = stored.substring(0, separator);
        final expected = stored.substring(separator + 1);
        return _constantTimeEquals(_hash(salt, pin), expected);
      }
      final legacy = await _secureStorage.read(key: _legacyPinStorageKey);
      if (legacy == null) return false;
      final ok = _constantTimeEquals(legacy, pin);
      if (ok) {
        try {
          final salt = _randomSalt();
          await _secureStorage.write(
            key: _pinHashStorageKey,
            value: '$salt:${_hash(salt, pin)}',
          );
          await _secureStorage.delete(key: _legacyPinStorageKey);
        } catch (e, s) {
          getIt<Talker>().error('[security] migrate PIN failed', e, s);
        }
      }
      return ok;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> clearPin() async {
    try {
      await _secureStorage.delete(key: _pinHashStorageKey);
      await _secureStorage.delete(key: _legacyPinStorageKey);
    } catch (e, s) {
      getIt<Talker>().error('[security] delete PIN failed', e, s);
    }
  }

  @override
  Future<bool> isBiometricsEnabled() async {
    final cached = _biometricsCache;
    if (cached != null) return cached;
    try {
      final enabled = (await _prefs()).getBool(_biometricsKey) ?? false;
      if (enabled && !await canCheckBiometrics()) {
        _biometricsCache = false;
        return false;
      }
      _biometricsCache = enabled;
      return enabled;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> setBiometricsEnabled(bool enabled) async {
    _biometricsCache = enabled;
    try {
      await (await _prefs()).setBool(_biometricsKey, enabled);
    } catch (e, s) {
      getIt<Talker>().error('[security] save biometrics failed', e, s);
    }
  }

  @override
  Future<bool> canCheckBiometrics() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      if (!canCheck) return false;
      final available = await _auth.getAvailableBiometrics();
      return available.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static const _androidAuthMessages = [
    AndroidAuthMessages(
      signInTitle: 'Требуется подтверждение',
      signInHint: 'Подтвердите личность',
      cancelButton: 'Отмена',
    ),
  ];

  static const _iosAuthMessages = [
    IOSAuthMessages(cancelButton: 'Отмена', localizedFallbackTitle: ''),
  ];

  @override
  Future<bool> authenticate({required String reason}) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        authMessages: [
          ..._androidAuthMessages,
          ..._iosAuthMessages,
        ],
        biometricOnly: true,
      );
    } catch (e, s) {
      getIt<Talker>().error('[security] biometric auth failed', e, s);
      return false;
    }
  }

  @override
  Future<ShareKeysWith> getShareKeysMode() async {
    try {
      final stored = (await _prefs()).getString(_shareKeysWithKey);
      if (stored != null) {
        return ShareKeysWith.values.byName(stored);
      }
    } catch (e, s) {
      getIt<Talker>().error('[security] read shareKeysWith failed', e, s);
    }
    if (getIt.isReadySync<Client>()) return getIt<Client>().shareKeysWith;
    return ShareKeysWith.crossVerifiedIfEnabled;
  }

  @override
  Future<void> setShareKeysMode(ShareKeysWith mode) async {
    if (getIt.isReadySync<Client>()) {
      getIt<Client>().shareKeysWith = mode;
    }
    try {
      await (await _prefs()).setString(_shareKeysWithKey, mode.name);
    } catch (e, s) {
      getIt<Talker>().error('[security] save shareKeysWith failed', e, s);
    }
  }

  static Future<ShareKeysWith> restoredShareKeysMode() async {
    try {
      final stored = (await SharedPreferences.getInstance()).getString(
        _shareKeysWithKey,
      );
      if (stored != null) return ShareKeysWith.values.byName(stored);
    } catch (_) {}
    return ShareKeysWith.crossVerifiedIfEnabled;
  }
}
