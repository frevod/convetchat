import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:matrix/matrix.dart';

class const SessionBackup({
  required final String? olmAccount,
  required final String accessToken,
  required final String userId,
  required final String homeserver,
  required final String? deviceId,
  final String? deviceName,
}) {
  factory fromJsonString(String json) =>
      SessionBackup.fromJson(jsonDecode(json) as Map<String, dynamic>);

  factory fromJson(Map<String, dynamic> json) => SessionBackup(
    olmAccount: json['olm_account'] as String?,
    accessToken: json['access_token'] as String,
    userId: json['user_id'] as String,
    homeserver: json['homeserver'] as String,
    deviceId: json['device_id'] as String?,
    deviceName: json['device_name'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'olm_account': olmAccount,
    'access_token': accessToken,
    'user_id': userId,
    'homeserver': homeserver,
    'device_id': deviceId,
    if (deviceName != null) 'device_name': deviceName,
  };

  @override
  String toString() => jsonEncode(toJson());
}

const _secureStorage = FlutterSecureStorage();

String _backupKey(String clientName) => 'convetchat_session_backup_$clientName';

Future<void> storeSessionBackup(Client client) async {
  final accessToken = client.accessToken;
  final homeserver = client.homeserver?.toString();
  final deviceId = client.deviceID;
  final userId = client.userID;
  if (accessToken == null ||
      homeserver == null ||
      deviceId == null ||
      userId == null) {
    return;
  }
  await _secureStorage.write(
    key: _backupKey(client.clientName),
    value: SessionBackup(
      olmAccount: client.encryption?.pickledOlmAccount,
      accessToken: accessToken,
      deviceId: deviceId,
      homeserver: homeserver,
      deviceName: client.deviceName,
      userId: userId,
    ).toString(),
  );
}

Future<void> restoreSessionBackup(Client client) async {
  final raw = await _secureStorage.read(key: _backupKey(client.clientName));
  if (raw == null) throw Exception('Нет бэкапа сессии');
  final backup = SessionBackup.fromJsonString(raw);
  await client.init(
    newToken: backup.accessToken,
    newOlmAccount: backup.olmAccount,
    newDeviceID: backup.deviceId,
    newDeviceName: backup.deviceName,
    newHomeserver: Uri.tryParse(backup.homeserver),
    newUserID: backup.userId,
    waitForFirstSync: false,
    waitUntilLoadCompletedLoaded: false,
  );
}

Future<void> deleteSessionBackup(String clientName) {
  return _secureStorage.delete(key: _backupKey(clientName));
}
