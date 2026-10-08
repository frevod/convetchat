import 'dart:async';

import 'package:convetchat/core/matrix/ru_matrix_localizations.dart';
import 'package:matrix/matrix.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../datasources/callkit_service.dart';
import '../datasources/matrix_rtc_signaling.dart';
import '../models/rtc_member.dart';

final class IncomingCallWatcher(final Client _client, final Talker _talker) {
  static const String _ringType = 'org.matrix.msc4075.rtc.notification';

  StreamSubscription? _syncSub;
  late final CallkitService _callkit = CallkitService(_talker);
  late final MatrixRtcSignaling _signaling = MatrixRtcSignaling(
    _client,
    _talker,
  );
  final Set<String> _shown = {};

  bool get running => _syncSub != null;

  void start() {
    if (running) return;
    _syncSub = _client.onSync.stream.listen(
      _onSync,
      onError: (Object e) => _talker.warning('[call] watcher sync error', e),
    );
  }

  Future<void> _onSync(SyncUpdate update) async {
    try {
      if (!_client.isLogged()) return;
      final candidates = _candidateRooms(update);
      for (final roomId in candidates) {
        await _evaluate(roomId);
      }
      await _cleanup();
    } catch (e) {
      _talker.warning('[call] watcher evaluate failed', e);
    }
  }

  Set<String> _candidateRooms(SyncUpdate update) {
    final rooms = <String>{};
    final join = update.rooms?.join;
    if (join == null) return rooms;
    for (final entry in join.entries) {
      final events = entry.value.timeline?.events;
      if (events == null) continue;
      for (final event in events) {
        final type = event.type;
        if (type == RtcMember.eventType || type == _ringType) {
          rooms.add(entry.key);
        }
      }
    }
    return rooms;
  }

  Future<void> _evaluate(String roomId) async {
    final room = _client.getRoomById(roomId);
    if (room == null) return;
    final members = _signaling.activeMembers(room);
    final others = members
        .where((m) => m.senderId != null && m.senderId != _client.userID)
        .toList();
    if (others.isEmpty) return;
    if (_signaling.ownMembership(room) != null) return;
    if (_shown.contains(roomId)) return;
    _shown.add(roomId);
    await _callkit.showIncoming(
      roomId: roomId,
      callerName: room.getLocalizedDisplayname(ruMatrixLocalizations),
    );
  }

  Future<void> _cleanup() async {
    if (_shown.isEmpty) return;
    final gone = <String>[];
    for (final roomId in _shown) {
      final room = _client.getRoomById(roomId);
      final members = room == null ? const [] : _signaling.activeMembers(room);
      final others = members.where(
        (m) => m.senderId != null && m.senderId != _client.userID,
      );
      if (others.isEmpty) gone.add(roomId);
    }
    for (final roomId in gone) {
      _shown.remove(roomId);
      await _callkit.endCall(roomId);
    }
  }

  Future<void> dispose() async {
    await _syncSub?.cancel();
    _syncSub = null;
    _shown.clear();
  }
}
