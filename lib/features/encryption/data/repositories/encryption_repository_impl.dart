import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/matrix/client_factory.dart';
import 'package:convetchat/features/encryption/domain/entities/crypto_identity_state.dart';
import 'package:convetchat/features/encryption/domain/entities/verified_device.dart';
import 'package:convetchat/features/encryption/domain/repositories/encryption_repository.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:matrix/encryption.dart';
import 'package:matrix/matrix.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talker_flutter/talker_flutter.dart';

class EncryptionRepositoryImpl(final Client _client)
    implements EncryptionRepository {
  static const _secureStorage = FlutterSecureStorage();

  String get _secureStorageKey => 'ssss_recovery_key_${_client.userID}';

  @override
  Future<CryptoIdentityState> getIdentityState() async {
    final state = await _client.getCryptoIdentityState();
    return CryptoIdentityState(
      connected: state.connected,
      crossSigningEnabled: state.crossSigningEnabled,
      initialized: state.initialized,
      keyBackupEnabled: state.keyBackupEnabled,
    );
  }

  @override
  Future<void> clearCryptoIdentity() async {
    await _client.clearCryptoIdentity();
    getIt<Talker>().warning('[e2ee] crypto identity cleared');
  }

  @override
  Future<String> setupNewIdentity({
    String? passphrase,
    required bool reset,
  }) async {
    final recoveryKey = await _client.initCryptoIdentity(
      passphrase: passphrase,
      wipeCrossSigning: reset,
      wipeKeyBackup: reset,
      wipeSecureStorage: reset,
      setupOnlineKeyBackup: true,
      setupMasterKey: true,
      setupSelfSigningKey: true,
      setupUserSigningKey: true,
    );
    await _setupDehydratedDevice(recoveryKey);
    return recoveryKey;
  }

  @override
  Future<void> restoreIdentity(String keyOrPassphrase) async {
    try {
      await _client.restoreCryptoIdentity(keyOrPassphrase, selfSign: false);
    } catch (e, s) {
      getIt<Talker>().error('[e2ee:restore] restoreCryptoIdentity failed', e, s);
      rethrow;
    }
    await _setupDehydratedDevice(keyOrPassphrase);
  }

  Future<void> _setupDehydratedDevice(String keyOrPassphrase) async {
    try {
      if (!await isDehydratedDevicesEnabled()) return;
      final encryption = _client.encryption;
      if (encryption == null || encryption.crossSigning.enabled != true) {
        return;
      }
      final handle = encryption.ssss.open();
      await handle.unlock(keyOrPassphrase: keyOrPassphrase, postUnlock: false);
      await _client.dehydratedDeviceSetup(handle);
    } catch (e, s) {
      getIt<Talker>().error('[e2ee:dehydrated] setup failed', e, s);
    }
  }

  @override
  Future<void> signOwnDevice(String keyOrPassphrase) async {
    try {
      await _client.encryption?.crossSigning.selfSign(
        keyOrPassphrase: keyOrPassphrase,
      );
    } catch (e, s) {
      getIt<Talker>().error(
        '[e2ee:restore] selfSign failed: device unverified',
        e,
        s,
      );
    }
  }

  @override
  Future<List<VerifiedDevice>> getVerifiedDevices() async {
    await _client.updateUserDeviceKeys();
    final userId = _client.userID;
    if (userId == null) return [];
    final devices =
        _client.userDeviceKeys[userId]?.deviceKeys.values
            .where(
              (device) =>
                  device.hasValidSignatureChain(verifiedByTheirMasterKey: true),
            )
            .map(
              (device) => VerifiedDevice(
                displayName: _deviceName(device.deviceDisplayName),
                lastActive: device.lastActive,
              ),
            )
            .toList() ??
        [];
    return devices;
  }

  @override
  Future<Map<String, bool>> getCacheDebugState() async {
    final encryption = _client.encryption;
    if (encryption == null) return {'encryption': false};
    final state = {
      'encryption': true,
      'crossSigning.isCached': await encryption.crossSigning.isCached(),
      'keyManager.isCached': await encryption.keyManager.isCached(),
      'ssss.self_signing':
          await encryption.ssss.getCached(EventTypes.CrossSigningSelfSigning) !=
          null,
      'ssss.user_signing':
          await encryption.ssss.getCached(EventTypes.CrossSigningUserSigning) !=
          null,
      'ssss.megolm':
          await encryption.ssss.getCached(EventTypes.MegolmBackup) != null,
    };
    return state;
  }

  @override
  Future<KeyVerification> startDeviceVerification() async {
    final userId = _client.userID;
    final devices = userId == null ? null : _client.userDeviceKeys[userId];
    if (devices == null) {
      throw Exception('Список устройств ещё не загружен, попробуйте снова');
    }
    final eligible = devices.deviceKeys.values
        .where((d) => d.hasValidSignatureChain(verifiedByTheirMasterKey: true))
        .map((d) => d.deviceId)
        .toList();
    if (eligible.isEmpty) {
      getIt<Talker>().warning(
        '[e2ee:verify] skipped: no master-key-signed devices, '
        'SAS request has no peer, key/passphrase required',
      );
    }
    final verification = await devices.startVerification();
    return verification;
  }

  @override
  Future<void> loadBackupKeys() async {
    final keyManager = _client.encryption?.keyManager;
    if (keyManager == null) {
      getIt<Talker>().warning('[e2ee:backup] keyManager unavailable');
      return;
    }
    try {
      await keyManager.loadAllKeys();
    } catch (e, s) {
      getIt<Talker>().error('[e2ee:backup] load keys failed', e, s);
    }
  }

  @override
  Future<void> requestMissingSessions() async {
    for (final room in _client.rooms) {
      final lastEvent = room.lastEvent;
      if (lastEvent == null ||
          lastEvent.messageType != MessageTypes.BadEncrypted ||
          lastEvent.content['can_request_session'] != true) {
        continue;
      }
      final sessionId = lastEvent.content.tryGet<String>('session_id');
      final senderKey = lastEvent.content.tryGet<String>('sender_key');
      if (sessionId != null && senderKey != null) {
        _client.encryption?.keyManager.maybeAutoRequest(
          room.id,
          sessionId,
          senderKey,
          tryOnlineBackup: true,
          onlineKeyBackupOnly: false,
        );
      }
    }
  }

  @override
  Future<bool> isDehydratedDevicesEnabled() async {
    return ClientFactory.experimentalDehydratedDevicesEnabled();
  }

  @override
  Future<void> setDehydratedDevicesEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(
      ClientFactory.experimentalDehydratedDevicesKey,
      enabled,
    );
    _client.enableDehydratedDevices = enabled;
    if (!enabled) return;
    try {
      final storedKey = await readSecureKey();
      if (storedKey == null || storedKey.isEmpty) return;
      await _setupDehydratedDevice(storedKey);
    } catch (e, s) {
      getIt<Talker>().error(
        '[e2ee:dehydrated] setup on enable failed',
        e,
        s,
      );
    }
  }

  @override
  Future<String?> readSecureKey() async {
    try {
      final key = await _secureStorage.read(key: _secureStorageKey);
      return key;
    } catch (e, s) {
      getIt<Talker>().error('[e2ee] read secure key failed', e, s);
      return null;
    }
  }

  @override
  Future<void> writeSecureKey(String? key) async {
    if (key == null) {
      await _secureStorage.delete(key: _secureStorageKey);
    } else {
      await _secureStorage.write(key: _secureStorageKey, value: key);
    }
  }

  static String _deviceName(String? name) =>
      (name?.isNotEmpty ?? false) ? name! : 'Неизвестное устройство';
}
