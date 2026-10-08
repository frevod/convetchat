import 'dart:async';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:convetchat/core/matrix/ru_matrix_localizations.dart';
import 'package:matrix/matrix.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../../domain/entities/call_exception.dart';
import '../../domain/entities/call_media.dart' as domain;
import '../../domain/entities/call_support.dart';
import '../../domain/entities/room_call_info.dart';
import '../../domain/repositories/call_repository.dart';
import '../datasources/callkit_service.dart';
import '../datasources/livekit_session.dart' as media;
import '../datasources/matrix_rtc_signaling.dart';
import '../models/rtc_member.dart';

final class CallRepositoryImpl(final Client _client, final Talker _talker)
    implements CallRepository {
  static const Duration _cacheTtl = Duration(hours: 1);
  static const Duration _probeTimeout = Duration(seconds: 5);

  List<String>? _cachedUrls;
  DateTime? _fetchedAt;
  media.LivekitSession? _livekit;
  late final CallkitService _callkit = CallkitService(_talker);
  StreamSubscription? _memberSub;
  CallHandle? _activeHandle;
  final Set<String> _sharedWith = {};

  MatrixRtcSignaling get _signaling => MatrixRtcSignaling(_client, _talker);

  Future<List<String>> _serviceUrls() async {
    final cached = _cachedUrls;
    if (cached != null &&
        _fetchedAt != null &&
        DateTime.now().difference(_fetchedAt!) < _cacheTtl) {
      return cached;
    }
    final urls = await _signaling.serviceUrls();
    if (urls.isNotEmpty) {
      _cachedUrls = urls;
      _fetchedAt = DateTime.now();
    }
    return urls;
  }

  Future<bool> _jwtReachable(String serviceUrl) async {
    try {
      final response = await http
          .get(Uri.parse(serviceUrl))
          .timeout(_probeTimeout);
      return response.statusCode < 500;
    } catch (e) {
      _talker.warning('[call] livekit jwt probe failed', e);
      return false;
    }
  }

  @override
  Future<CallSupportResult> checkSupport() async {
    if (!_client.isLogged()) {
      return const CallSupportResult.unsupported(
        CallSupportFailure.voipUnavailable,
      );
    }
    try {
      if (await Permission.microphone.status.isPermanentlyDenied) {
        return const CallSupportResult.unsupported(
          CallSupportFailure.microphonePermanentlyDenied,
        );
      }
    } catch (e) {
      _talker.warning('[call] mic permission check failed', e);
    }
    final urls = await _serviceUrls();
    if (urls.isEmpty) {
      return const CallSupportResult.unsupported(CallSupportFailure.noRtcFocus);
    }
    if (!await _jwtReachable(urls.first)) {
      return const CallSupportResult.unsupported(
        CallSupportFailure.jwtUnreachable,
      );
    }
    return const CallSupportResult.supported();
  }

  @override
  Future<CallHandle> startVoiceCall(String roomId) =>
      _join(roomId, ring: true);

  @override
  Future<CallHandle> answerVoiceCall(String roomId) =>
      _join(roomId, ring: false);

  Future<CallHandle> _join(String roomId, {required bool ring}) async {
    if (!_client.isLogged()) {
      throw const CallException(CallSupportFailure.voipUnavailable);
    }
    await _memberSub?.cancel();
    await _livekit?.dispose();
    _memberSub = null;
    _activeHandle = null;
    _sharedWith.clear();
    _livekit = null;
    final mic = await Permission.microphone.request();
    if (!mic.isGranted) {
      throw CallException(
        mic.isPermanentlyDenied
            ? CallSupportFailure.microphonePermanentlyDenied
            : CallSupportFailure.voipUnavailable,
      );
    }
    final room = _client.getRoomById(roomId);
    if (room == null) {
      throw const CallException(CallSupportFailure.voipUnavailable);
    }
    try {
      final members = _signaling.activeMembers(room);
      final urls = members
          .expand((m) => m.fociPreferred)
          .map((f) => f.livekitServiceUrl)
          .where((url) => url.isNotEmpty)
          .toSet()
          .toList();
      final effective = urls.isNotEmpty ? urls : await _serviceUrls();
      if (effective.isEmpty) {
        throw const CallException(CallSupportFailure.noRtcFocus);
      }
      final memberEventId = await _signaling.setMembership(room, effective);
      for (var i = 0; i < 10; i++) {
        if (_signaling.ownMembership(room) != null) break;
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }
      if (ring) {
        await _signaling.ring(
          room,
          hasActiveCall: members.isNotEmpty,
          memberEventId: memberEventId,
        );
      }
      final credentials = await _signaling.credentials(room, effective);
      final livekit = _livekit = media.LivekitSession(_client, _talker);
      await livekit.init();
      await livekit.connect(credentials.url, credentials.jwt);
      final generated = await livekit.generateKey();
      await _shareKey(room, livekit, generated, members);
      await Future<void>.delayed(const Duration(seconds: 2));
      await livekit.activateOwnKey(generated.key, generated.index);
      final handle = CallHandle(roomId: roomId, groupCallId: roomId);
      _activeHandle = handle;
      _memberSub = _client.onSync.stream.listen(
        (_) => _resyncMembers(),
        onError: (Object e) => _talker.warning('[call] member resync error', e),
      );
      await _callkit.endCall(roomId);
      return handle;
    } catch (e) {
      _talker.error('[call] startVoiceCall failed', e);
      await _memberSub?.cancel();
      await _livekit?.dispose();
      _memberSub = null;
      _activeHandle = null;
      _sharedWith.clear();
      _livekit = null;
      try {
        if (_signaling.ownMembership(room) != null) {
          await _signaling.leave(room);
        }
      } catch (_) {}
      if (e is CallException) rethrow;
      throw CallException(CallSupportFailure.voipUnavailable, e);
    }
  }

  Future<void> _shareKey(
    Room room,
    media.LivekitSession livekit,
    ({Uint8List key, int index}) own,
    List<RtcMember> members,
  ) async {
    final ownId = livekit.ownMemberId ?? '';
    final ids = <String, RtcMember>{};
    for (final m in members) {
      if (m.senderId == _client.userID && m.deviceId == _client.deviceID) {
        continue;
      }
      final base = m.membershipId ?? '${m.senderId}:${m.deviceId}';
      final created = m.createdAt?.millisecondsSinceEpoch ?? 0;
      ids['$base@$created'] = m;
    }
    final freshIds = ids.keys.where((id) => !_sharedWith.contains(id)).toList();
    if (freshIds.isEmpty) return;
    final actual = (key: own.key, index: own.index);
    final targets = [for (final id in freshIds) ids[id]!];
    final devices = await _signaling.deviceKeysFor(targets, ownId);
    await _signaling.shareCallKey(
      room: room,
      key: actual.key,
      index: actual.index,
      ownMemberId: ownId,
      deviceKeys: devices,
    );
    _sharedWith.addAll(freshIds);
  }

  bool _resyncing = false;

  Future<void> _resyncMembers() async {
    if (_resyncing) return;
    _resyncing = true;
    try {
      final handle = _activeHandle;
      final livekit = _livekit;
      if (handle == null || livekit == null || !livekit.hasKey) return;
      final room = _client.getRoomById(handle.roomId);
      if (room == null) return;
      final members = _signaling.activeMembers(room);
      if (members.any((m) {
        final base = m.membershipId ?? '${m.senderId}:${m.deviceId}';
        final created = m.createdAt?.millisecondsSinceEpoch ?? 0;
        return !_sharedWith.contains('$base@$created');
      })) {
        final rotated = await livekit.generateKey();
        await _shareKey(room, livekit, rotated, members);
        await Future<void>.delayed(const Duration(seconds: 2));
        await livekit.activateOwnKey(rotated.key, rotated.index);
      }
    } catch (e) {
      _talker.warning('[call] member resync failed', e);
    } finally {
      _resyncing = false;
    }
  }

  @override
  Stream<domain.CallMediaEvent> mediaEvents(CallHandle handle) {
    final livekit = _livekit;
    if (livekit == null) return const Stream.empty();
    return livekit.events.map((event) => switch (event) {
      media.CallMediaEvent.remoteJoined => domain.CallMediaEvent.remoteJoined,
      media.CallMediaEvent.remoteLeft => domain.CallMediaEvent.remoteLeft,
      media.CallMediaEvent.e2eeFailed => domain.CallMediaEvent.e2eeFailed,
    });
  }

  @override
  Future<void> setMicrophoneMuted(CallHandle handle, bool muted) =>
      _livekit?.setMicrophoneMuted(muted) ?? Future.value();

  @override
  Future<void> setSpeakerphone(bool enabled) =>
      _livekit?.setSpeakerphone(enabled) ?? Future.value();

  @override
  Future<void> setCallConnected(CallHandle handle) =>
      _callkit.setConnected(handle.roomId);

  @override
  Stream<RoomCallInfo> watchRoomCall(String roomId) {
    late final StreamController<RoomCallInfo> controller;
    StreamSubscription? syncSub;
    RoomCallInfo last = RoomCallInfo.none;
    void emit() {
      final room = _client.getRoomById(roomId);
      final info = room == null ? RoomCallInfo.none : _roomCallInfo(room);
      if (info == last || controller.isClosed) return;
      last = info;
      controller.add(info);
    }

    controller = StreamController<RoomCallInfo>.broadcast(
      onListen: emit,
      onCancel: () => syncSub?.cancel(),
    );
    syncSub = _client.onSync.stream.listen(
      (_) => emit(),
      onError: (Object e) => _talker.warning('[call] room watch error', e),
    );
    return controller.stream;
  }

  RoomCallInfo _roomCallInfo(Room room) {
    final members = _signaling.activeMembers(room);
    final others = members.where(
      (m) => m.senderId != null && m.senderId != _client.userID,
    );
    return RoomCallInfo(
      active: others.isNotEmpty,
      joined: _signaling.ownMembership(room) != null,
      roomName: room.getLocalizedDisplayname(ruMatrixLocalizations),
    );
  }

  @override
  Future<void> hangup(CallHandle handle) async {
    try {
      await _memberSub?.cancel();
      await _callkit.endCall(handle.roomId);
      await _livekit?.dispose();
      final room = _client.getRoomById(handle.roomId);
      if (room != null) await _signaling.leave(room);
    } catch (e, s) {
      _talker.error('[call] hangup failed', e, s);
    } finally {
      _memberSub = null;
      _activeHandle = null;
      _sharedWith.clear();
      _livekit = null;
    }
  }
}
