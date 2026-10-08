import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:livekit_client/livekit_client.dart' as lk;
import 'package:matrix/matrix.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../models/call_keys.dart';

enum CallMediaEvent() { remoteJoined, remoteAudio, remoteLeft, e2eeFailed }

final class LivekitSession(final Client _client, final Talker _talker) {
  lk.Room? _room;
  lk.BaseKeyProvider? _keyProvider;
  StreamSubscription? _keysSub;

  final StreamController<CallMediaEvent> _events =
      StreamController.broadcast();

  Stream<CallMediaEvent> get events => _events.stream;

  String? _ownMemberId;
  Uint8List? _lastKey;
  int _lastIndex = 0;
  bool _muted = false;

  bool get isMuted => _muted;
  bool get hasKey => _lastKey != null;

  Future<void> init() async {
    await lk.LiveKitClient.initialize();
    final options = rtc.KeyProviderOptions(
      sharedKey: false,
      ratchetSalt: Uint8List.fromList('LKFrameEncryptionKey'.codeUnits),
      ratchetWindowSize: 0,
      discardFrameWhenCryptorNotReady: true,
      keyDerivationAlgorithm: rtc.KeyDerivationAlgorithm.kHKDF,
      keyRingSize: 255,
    );
    final native = await rtc.frameCryptorFactory.createDefaultKeyProvider(
      options,
    );
    final keyProvider = _keyProvider = lk.BaseKeyProvider(native, options);
    final room = _room = lk.Room(
      roomOptions: lk.RoomOptions(
        adaptiveStream: true,
        dynacast: true,
        defaultAudioCaptureOptions: lk.AudioCaptureOptions(
          echoCancellation: true,
          noiseSuppression: true,
          autoGainControl: true,
          highPassFilter: true,
        ),
        defaultAudioOutputOptions: lk.AudioOutputOptions(speakerOn: false),
        encryption: lk.E2EEOptions(keyProvider: keyProvider),
      ),
    );
    room.events.on<lk.ParticipantConnectedEvent>((event) {
      if (event.participant.identity == room.localParticipant?.identity) return;
      _events.add(CallMediaEvent.remoteJoined);
    });
    room.events.on<lk.ParticipantDisconnectedEvent>((event) {
      _events.add(CallMediaEvent.remoteLeft);
    });
    room.events.on<lk.TrackE2EEStateEvent>((event) {
      if (event.state == lk.E2EEState.kOk) {
        return;
      }
      if (event.state == lk.E2EEState.kNew ||
          event.state == lk.E2EEState.kKeyRatcheted) {
        return;
      }
      if (event.state == lk.E2EEState.kMissingKey) {
        _talker.warning('[call] livekit waiting for e2ee key');
        return;
      }
      _talker.error('[call] livekit e2ee failed: ${event.state}');
      _events.add(CallMediaEvent.e2eeFailed);
    });
    room.events.on<lk.TrackSubscribedEvent>((_) {});
    room.events.on<lk.TrackMutedEvent>((event) {
      _talker.warning('[call] livekit remote track muted ${event.publication.kind}');
    });
    room.events.on<lk.TrackUnmutedEvent>((_) {});
    _keysSub = _client.onToDeviceEvent.stream
        .where((event) => event.type == CallKeysContent.eventType)
        .listen(_onCallKeys);
  }

  Future<void> _onCallKeys(ToDeviceEvent event) async {
    try {
      final keyProvider = _keyProvider;
      if (keyProvider == null) return;
      final content = CallKeysContent.fromJson(
        Map<String, Object?>.from(event.content),
      );
      if (event.sender == _client.userID &&
          content.member.claimedDeviceId == _client.deviceID) {
        return;
      }
      final participantId =
          '${event.sender}:${content.member.claimedDeviceId}';
      await keyProvider.setRawKey(
        base64Decode(content.keys.key),
        participantId: participantId,
        keyIndex: content.keys.index,
      );
    } catch (e) {
      _talker.error('[call] e2ee key install failed', e);
    }
  }

  Future<void> connect(String url, String jwt) async {
    final room = _room;
    if (room == null) throw StateError('LivekitSession not initialized');
    await room
        .connect(
          url,
          jwt,
          fastConnectOptions: lk.FastConnectOptions(
            microphone: lk.TrackOption(
              track: await lk.LocalAudioTrack.create(),
            ),
          ),
        )
        .timeout(const Duration(seconds: 30));
  }

  Future<({Uint8List key, int index})> generateKey() async {
    final keyProvider = _keyProvider;
    if (keyProvider == null) throw StateError('LivekitSession not initialized');
    _ownMemberId = '${_client.userID}:${_client.deviceID}';
    final existing = _lastKey;
    final index = existing == null
        ? keyProvider.getLatestIndex(_ownMemberId!)
        : (_lastIndex + 1) % 256;
    final rng = Random.secure();
    final key = Uint8List(16);
    key.setAll(0, Iterable.generate(key.length, (_) => rng.nextInt(256)));
    _lastKey = key;
    _lastIndex = index;
    return (key: key, index: index);
  }

  Future<void> activateOwnKey(Uint8List key, int index) async {
    final keyProvider = _keyProvider;
    final room = _room;
    if (keyProvider == null || room == null) {
      throw StateError('LivekitSession not initialized');
    }
    final ownMemberId = _ownMemberId ?? '';
    await keyProvider.setRawKey(
      key,
      participantId: ownMemberId,
      keyIndex: index,
    );
    await room.e2eeManager?.setKeyIndex(
      index,
      participantIdentity: ownMemberId,
    );
  }

  String? get ownMemberId => _ownMemberId;

  Future<void> setMicrophoneMuted(bool muted) async {
    _muted = muted;
    final pubs = _room?.localParticipant?.audioTrackPublications ?? const [];
    for (final pub in pubs) {
      if (muted) {
        await pub.mute();
      } else {
        await pub.unmute();
      }
    }
  }

  Future<void> setSpeakerphone(bool enabled) =>
      lk.AudioManager.instance.setSpeakerOutputPreferred(enabled);

  Future<void> dispose() async {
    await _keysSub?.cancel();
    _keysSub = null;
    final room = _room;
    _room = null;
    if (room != null) {
      try {
        if (room.connectionState != lk.ConnectionState.disconnected) {
          await room.disconnect();
        }
      } catch (e) {
        _talker.warning('[call] livekit disconnect failed', e);
      }
      await room.dispose();
    }
    try {
      // ignore: experimental_member_use
      await lk.AudioManager.instance.deactivateAudioSession();
    } catch (e) {
      _talker.warning('[call] audio session deactivate failed', e);
    }
    await _events.close();
  }
}
