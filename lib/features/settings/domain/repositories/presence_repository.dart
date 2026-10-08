import 'package:convetchat/core/presence/presence_mode.dart';

abstract class PresenceRepository() {
  static const storageKey = 'presence.mode';

  Future<PresenceMode> ownMode();

  Future<void> setOwnMode(PresenceMode mode);

  Stream<PresenceMode> watchOwnMode();

  Future<bool?> busySupported();
}
