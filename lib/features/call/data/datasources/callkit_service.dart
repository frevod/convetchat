import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:talker_flutter/talker_flutter.dart';

final class CallkitService(final Talker _talker) {
  static const String _appName = 'ConvetChat';
  static const int _timeoutMillis = 30000;

  Stream<CallEvent?> get events => FlutterCallkitIncoming.onEvent;

  String callId(String roomId) => 'convetchat|$roomId';

  Future<void> showIncoming({
    required String roomId,
    required String callerName,
  }) async {
    try {
      final active = await FlutterCallkitIncoming.activeCalls();
      if (active.any((call) => call.id == callId(roomId))) return;
      await FlutterCallkitIncoming.showCallkitIncoming(
        CallKitParams(
          id: callId(roomId),
          nameCaller: callerName,
          appName: _appName,
          type: 0,
          duration: _timeoutMillis,
          extra: {'roomId': roomId, 'roomName': callerName},
          android: const AndroidParams(
            incomingCallNotificationChannelName: 'Входящие звонки',
            missedCallNotificationChannelName: 'Пропущенные звонки',
          ),
          missedCallNotification: const NotificationParams(
            showNotification: true,
            subtitle: 'Пропущенный звонок',
            isShowCallback: false,
          ),
        ),
      );
    } catch (e, s) {
      _talker.error('[call] callkit show failed', e, s);
    }
  }

  Future<List<CallKitParams>> activeCalls() async {
    try {
      return await FlutterCallkitIncoming.activeCalls();
    } catch (e) {
      _talker.warning('[call] callkit activeCalls failed', e);
      return const [];
    }
  }

  Future<void> setConnected(String roomId) async {
    try {
      await FlutterCallkitIncoming.setCallConnected(callId(roomId));
    } catch (e) {
      _talker.warning('[call] callkit setConnected failed', e);
    }
  }

  Future<void> endCall(String roomId) async {
    try {
      await FlutterCallkitIncoming.endCall(callId(roomId));
    } catch (e) {
      _talker.warning('[call] callkit endCall failed', e);
    }
  }
}
