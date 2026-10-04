import 'dart:async';

import 'package:convetchat/core/di/locator.dart';
import 'package:matrix/encryption.dart';
import 'package:matrix/matrix.dart';
import 'package:talker_flutter/talker_flutter.dart';

StreamSubscription<RoomKeyRequest>? _keyForwardSubscription;

void initKeyForwardListener() {
  _keyForwardSubscription?.cancel();
  final client = getIt<Client>();
  _keyForwardSubscription = client.onRoomKeyRequest.stream.listen((
    request,
  ) async {
    final requesting = request.requestingDevice;

    final isOwnSession =
        requesting.userId == client.userID &&
        client.userDeviceKeys[client.userID]?.deviceKeys.values.any(
              (device) => device.curve25519Key == requesting.curve25519Key,
            ) ==
            true;
    if (!isOwnSession) {
      return;
    }
    try {
      await request.forwardKey();
    } catch (e, s) {
      getIt<Talker>().error('Не удалось переслать ключ', e, s);
    }
  });
}
