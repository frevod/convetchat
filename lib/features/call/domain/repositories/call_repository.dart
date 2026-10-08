import '../entities/call_media.dart';
import '../entities/call_support.dart';
import '../entities/room_call_info.dart';

class const CallHandle({
  required final String roomId,
  required final String groupCallId,
});

abstract class CallRepository() {
  Future<CallSupportResult> checkSupport();

  Future<CallHandle> startVoiceCall(String roomId);

  Future<CallHandle> answerVoiceCall(String roomId);

  Future<void> setCallConnected(CallHandle handle);

  Stream<RoomCallInfo> watchRoomCall(String roomId);

  Stream<CallMediaEvent> mediaEvents(CallHandle handle);

  Future<void> setMicrophoneMuted(CallHandle handle, bool muted);

  Future<void> setSpeakerphone(bool enabled);

  Future<void> hangup(CallHandle handle);
}
