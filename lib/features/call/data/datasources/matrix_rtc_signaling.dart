import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:matrix/matrix.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../models/call_keys.dart';
import '../models/rtc_credentials.dart';
import '../models/rtc_member.dart';

class MatrixRtcSignaling(final Client _client, final Talker _talker) {
  static const Duration _probeTimeout = Duration(seconds: 5);

  String _stateKey() => '_${_client.userID}_${_client.deviceID}_m.call';

  Future<List<String>> serviceUrls() async {
    try {
      final wellKnown = await _client.getWellknown().timeout(_probeTimeout);
      final foci =
          wellKnown.additionalProperties['org.matrix.msc4143.rtc_foci'];
      if (foci is! List) return const [];
      final urls = <String>[];
      for (final focus in foci) {
        if (focus is Map) {
          final url = focus['livekit_service_url'];
          if (url is String && url.isNotEmpty) urls.add(url);
        }
      }
      return urls;
    } catch (e) {
      _talker.warning('[call] well-known foci fetch failed', e);
      return const [];
    }
  }

  List<RtcMember> activeMembers(Room room) {
    final states = room.states[RtcMember.eventType];
    if (states == null) return const [];
    final now = DateTime.now();
    final members = <RtcMember>[];
    for (final event in states.values) {
      try {
        final content = Map<String, Object?>.from(event.content as Map);
        final member = RtcMember.fromJson(
          content,
          senderId: event.senderId,
        );
        if (member.focusActive?.type != 'livekit') continue;
        if (member.isExpired(now)) continue;
        members.add(member);
      } catch (e) {
        _talker.warning('[call] skip invalid rtc member event', e);
      }
    }
    return members;
  }

  RtcMember? ownMembership(Room room) {
    try {
      final event = room.getState(RtcMember.eventType, _stateKey());
      if (event == null || event.content.isEmpty) return null;
      return RtcMember.fromJson(
        Map<String, Object?>.from(event.content),
        senderId: event.senderId,
      );
    } catch (e) {
      _talker.warning('[call] own membership parse failed', e);
      return null;
    }
  }

  Future<String> setMembership(
    Room room,
    List<String> urls, {
    RtcCallIntent intent = RtcCallIntent.audio,
  }) {
    final member = RtcMember(
      application: 'm.call',
      callId: '',
      deviceId: _client.deviceID,
      createdAt: DateTime.now(),
      expires: const Duration(hours: 4),
      fociPreferred: [
        for (final url in urls)
          RtcFocusPreferred(
            type: 'livekit',
            livekitServiceUrl: url,
            livekitAlias: room.id,
          ),
      ],
      focusActive: const RtcFocusActive(
        type: 'livekit',
        focusSelection: 'oldest_membership',
      ),
      callIntent: intent,
      membershipId: '${_client.userID}:${_client.deviceID}',
      scope: 'm.room',
      senderId: null,
    );
    return _client.setRoomStateWithKey(
      room.id,
      RtcMember.eventType,
      _stateKey(),
      member.toJson(),
    );
  }

  Future<String?> ring(
    Room room, {
    bool hasActiveCall = false,
    String? memberEventId,
  }) {
    if (hasActiveCall) return Future.value(null);
    final dmUserId = room.directChatMatrixID;
    if (dmUserId != null) {
      return room.sendRtcNotification(
        type: RtcNotificationType.ring,
        userIds: [dmUserId],
        memberEventId: memberEventId,
      );
    }
    return room.sendRtcNotification(
      type: RtcNotificationType.notification,
      mentionRoom: true,
      memberEventId: memberEventId,
    );
  }

  Future<RtcCredentials> credentials(Room room, List<String> urls) async {    final openId = await _client
        .requestOpenIdToken(_client.userID!, {})
        .timeout(_probeTimeout);
    Object? lastError;
    for (final url in urls) {
      try {
        final endpoint = '${url.replaceAll(RegExp(r'/+$'), '')}/sfu/get';
        final response = await http
            .post(
              Uri.parse(endpoint),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'room': room.id,
                'openid_token': openId.toJson(),
                'device_id': _client.deviceID,
              }),
            )
            .timeout(_probeTimeout);
        if (response.statusCode != 200) {
          throw Exception('sfu/get: ${response.statusCode}');
        }
        final json =
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, Object?>;
        final credentials = RtcCredentials.fromJson(json);
        if (credentials.url.isEmpty || credentials.jwt.isEmpty) {
          throw Exception('sfu/get: empty credentials');
        }
        return credentials;
      } catch (e) {
        lastError = e;
        _talker.warning('[call] sfu auth failed for $url', e);
      }
    }
    throw Exception('LiveKit auth failed: $lastError');
  }

  Future<void> leave(Room room) => _client.setRoomStateWithKey(
    room.id,
    RtcMember.eventType,
    _stateKey(),
    {},
  );

  Future<List<DeviceKeys>> deviceKeysFor(
    List<RtcMember> members,
    String ownId,
  ) async {
    try {
      final loading = _client.userDeviceKeysLoading;
      if (loading != null) {
        await loading.timeout(const Duration(seconds: 5));
      }
    } catch (_) {}
    final keys = <DeviceKeys>[];
    for (final member in members) {
      final userId = member.senderId;
      final deviceId = member.deviceId;
      final membershipId = member.membershipId ?? '$userId:$deviceId';
      if (membershipId == ownId) continue;
      if (userId == null || deviceId == null) {
        _talker.warning('[call] member without ids: $membershipId');
        continue;
      }
      final deviceKeys = _client
          .userDeviceKeys[userId]
          ?.deviceKeys[deviceId];
      if (deviceKeys == null) {
        _talker.warning('[call] no device keys for $membershipId');
        continue;
      }
      keys.add(deviceKeys);
    }
    return keys;
  }

  Future<void> shareCallKey({
    required Room room,
    required Uint8List key,
    required int index,
    required String ownMemberId,
    required List<DeviceKeys> deviceKeys,
  }) {
    if (deviceKeys.isEmpty) {
      _talker.warning('[call] no devices to share call key with');
      return Future.value();
    }
    final content = CallKeysContent(
      keys: CallKeysEntry(index: index, key: base64Encode(key)),
      member: CallKeysMember(
        id: ownMemberId,
        claimedDeviceId: _client.deviceID ?? '',
      ),
      roomId: room.id,
      session: const CallKeysSession(
        application: 'm.call',
        callId: '',
        scope: 'm.room',
      ),
      sentTs: DateTime.now().millisecondsSinceEpoch,
    );
    return _client.sendToDeviceEncrypted(
      deviceKeys,
      CallKeysContent.eventType,
      content.toJson(),
    );
  }
}
