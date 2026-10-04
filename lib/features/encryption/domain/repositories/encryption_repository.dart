import 'package:convetchat/features/encryption/domain/entities/crypto_identity_state.dart';
import 'package:convetchat/features/encryption/domain/entities/verified_device.dart';
import 'package:matrix/encryption.dart';

abstract class EncryptionRepository() {
  Future<CryptoIdentityState> getIdentityState();

  Future<String> setupNewIdentity({String? passphrase, required bool reset});

  Future<void> clearCryptoIdentity();

  Future<void> restoreIdentity(String keyOrPassphrase);

  Future<void> signOwnDevice(String keyOrPassphrase);

  Future<List<VerifiedDevice>> getVerifiedDevices();

  Future<Map<String, bool>> getCacheDebugState();

  Future<KeyVerification> startDeviceVerification();

  Future<void> requestMissingSessions();

  Future<void> loadBackupKeys();

  Future<String?> readSecureKey();

  Future<void> writeSecureKey(String? key);
}
