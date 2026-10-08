import 'dart:async';

import 'package:convetchat/core/matrix/server_capabilities.dart';
import 'package:convetchat/core/presence/presence_mode.dart';
import 'package:convetchat/features/settings/domain/repositories/presence_repository.dart';
import 'package:matrix/matrix.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PresenceRepositoryImpl(final Client _client)
    implements PresenceRepository {
  final _controller = StreamController<PresenceMode>.broadcast();

  @override
  Future<PresenceMode> ownMode() async {
    final prefs = await SharedPreferences.getInstance();
    return PresenceMode.fromName(
      prefs.getString(PresenceRepository.storageKey),
    );
  }

  @override
  Future<void> setOwnMode(PresenceMode mode) async {
    await _apply(mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PresenceRepository.storageKey, mode.name);
    if (!_controller.isClosed) _controller.add(mode);
  }

  @override
  Stream<PresenceMode> watchOwnMode() async* {
    yield await ownMode();
    yield* _controller.stream;
  }

  @override
  Future<bool?> busySupported() async {
    final versions = await _client.getVersions();
    return ServerCapabilities.supportsBusyPresence(versions.unstableFeatures);
  }

  Future<void> _apply(PresenceMode mode) async {
    final userId = _client.userID;
    if (userId == null) return;
    _client.syncPresence = mode == PresenceMode.online
        ? null
        : mode.presenceType;
    if (mode == PresenceMode.online) return;
    await _client.setPresence(userId, mode.presenceType);
  }
}
