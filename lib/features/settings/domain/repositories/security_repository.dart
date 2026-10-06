import 'package:matrix/matrix.dart';

abstract class SecurityRepository() {
  Future<bool> isAppLockEnabled();
  Future<void> setAppLockEnabled(bool enabled);

  Future<bool> hasPin();
  Future<void> setPin(String pin);
  Future<bool> verifyPin(String pin);
  Future<void> clearPin();

  Future<bool> isBiometricsEnabled();
  Future<void> setBiometricsEnabled(bool enabled);

  Future<bool> canCheckBiometrics();
  Future<bool> authenticate({required String reason});

  Future<ShareKeysWith> getShareKeysMode();
  Future<void> setShareKeysMode(ShareKeysWith mode);
}
