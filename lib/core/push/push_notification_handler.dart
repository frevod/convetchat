import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:convetchat/core/logging/talker.dart';
import 'package:convetchat/core/logging/talker_file_sink.dart';
import 'package:convetchat/core/matrix/client_factory.dart';
import 'package:convetchat/core/push/mention_filter.dart';
import 'package:convetchat/core/push/push_config.dart';
import 'package:convetchat/core/matrix/ru_matrix_localizations.dart';
import 'package:convetchat/features/call/data/datasources/callkit_service.dart';
import 'package:convetchat/features/call/data/datasources/matrix_rtc_signaling.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:matrix/matrix.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talker_flutter/talker_flutter.dart';

enum PushHandleResult() {
  shown,

  suppressed,

  failed,
}

const Duration _backgroundEnrichBudget = Duration(seconds: 8);

const Duration _fallbackDelay = Duration(seconds: 6);

const String markAsReadActionId = 'markAsRead';

const String replyActionId = 'reply';

const String muteActionId = 'mute';

const String _notificationGroup = 'convetchat';

final int _summaryNotificationId = 'convetchat_summary'.hashCode;

int roomNotificationId(String roomId) => roomId.hashCode;

Future<bool> contentPreviewEnabled() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notifications.contentPreview') ?? true;
  } catch (_) {
    return true;
  }
}

Future<bool> _isMentionsOnlyRoom(String roomId) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(mentionsOnlyRoomsKey)?.contains(roomId) ?? false;
  } catch (_) {
    return false;
  }
}

bool _mentionsUser(Event event, Client client) {
  final userId = client.userID;
  if (userId == null) return true;
  final displayName = event.room
      .unsafeGetUserFromMemoryOrFallback(userId)
      .displayName;
  final body = event.content.tryGet<String>('body') ?? '';
  return mentionsUser(
    content: event.content,
    plainBody: body,
    userId: userId,
    displayName: displayName,
  );
}

const AndroidNotificationAction _markAsReadAction = AndroidNotificationAction(
  markAsReadActionId,
  'Отметить прочитанным',
  semanticAction: SemanticAction.markAsRead,
  cancelNotification: true,
);

const AndroidNotificationAction _replyAction = AndroidNotificationAction(
  replyActionId,
  'Ответить',
  semanticAction: SemanticAction.reply,
  cancelNotification: true,
  inputs: <AndroidNotificationActionInput>[
    AndroidNotificationActionInput(label: 'Написать сообщение'),
  ],
  allowGeneratedReplies: true,
);

const AndroidNotificationAction _muteAction = AndroidNotificationAction(
  muteActionId,
  'Заглушить',
  semanticAction: SemanticAction.mute,
  cancelNotification: true,
);

const List<AndroidNotificationAction> _messageActions =
    <AndroidNotificationAction>[_replyAction, _markAsReadAction, _muteAction];

const String pushActionPortName = 'convetchat_push_action_port';

String serializeNotificationResponse(NotificationResponse response) =>
    jsonEncode({
      'type': response.notificationResponseType.name,
      'id': response.id,
      'actionId': response.actionId,
      'input': response.input,
      'payload': response.payload,
    });

NotificationResponse? deserializeNotificationResponse(String raw) {
  try {
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final typeName = json['type'] as String?;
    final type = NotificationResponseType.values
        .where((t) => t.name == typeName)
        .firstOrNull;
    if (type == null) return null;
    return NotificationResponse(
      notificationResponseType: type,
      id: (json['id'] as num?)?.toInt(),
      actionId: json['actionId'] as String?,
      input: json['input'] as String?,
      payload: json['payload'] as String?,
    );
  } catch (_) {
    return null;
  }
}

List<AndroidNotificationAction>? _actionsForEventType(String eventType) {
  switch (eventType) {
    case EventTypes.Message:
    case EventTypes.Encrypted:
    case EventTypes.Sticker:
      return _messageActions;
    default:
      return null;
  }
}

void registerPushBackgroundHandler() {
  if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) return;
  try {
    FirebaseMessaging.onBackgroundMessage(onBackgroundMessage);
  } catch (_) {}
}

@pragma('vm:entry-point')
Future<void> onBackgroundMessage(RemoteMessage message) async {
  DartPluginRegistrant.ensureInitialized();
  final data = message.data;
  final eventId = data['event_id'] as String?;
  final roomId = data['room_id'] as String?;

  if (eventId == null || roomId == null) {
    return;
  }

  final talker = createTalker();
  try {
    await TalkerFileSink.init();
  } catch (_) {}
  final localNotifications = FlutterLocalNotificationsPlugin();
  await _init(localNotifications, talker);

  var settled = false;
  var fallbackShown = false;

  Future<void> showFallback() async {
    if (fallbackShown) return;
    fallbackShown = true;
    await showFallbackNotification(
      roomId: roomId,
      eventId: eventId,
      localNotifications: localNotifications,
      talker: talker,
    );
  }

  Timer(_fallbackDelay, () {
    if (settled || fallbackShown) return;
    talker.warning('[push:bg] enrich timeout, fallback notification required');
    unawaited(showFallback());
  });

  try {
    if (!await contentPreviewEnabled()) {
      settled = true;
      await showFallback();
      return;
    }
    final result = await _enrich(
      roomId: roomId,
      eventId: eventId,
      localNotifications: localNotifications,
      talker: talker,
    ).timeout(_backgroundEnrichBudget);
    settled = true;
    if (result == PushHandleResult.failed) {
      await showFallback();
    }
  } on TimeoutException {
    settled = true;
    await showFallback();
    talker.warning(
      '[push:bg] enrich budget exceeded ($_backgroundEnrichBudget)',
    );
  } catch (e, s) {
    settled = true;
    await showFallback();
    talker.error('[push:bg] unhandled error', e, s);
  }
}

Future<PushHandleResult> _enrich({
  required String roomId,
  required String eventId,
  required FlutterLocalNotificationsPlugin localNotifications,
  required Talker talker,
}) async {
  Client? client;
  try {
    client = await ClientFactory.createClient();
    if (!client.isLogged()) {
      talker.warning('[push:bg] client not logged in, suppressed');
      return PushHandleResult.suppressed;
    }
    client
      ..backgroundSync = false
      ..syncPresence = PresenceType.offline;
    try {
      await client.abortSync();
    } catch (_) {}

    final result = await handlePushNotification(
      notification: PushNotification(eventId: eventId, roomId: roomId),
      client: client,
      localNotifications: localNotifications,
      talker: talker,
      lookupTimeout: const Duration(seconds: 6),
    );

    if (result == PushHandleResult.suppressed) {
      await _cancelRoom(roomId, localNotifications, talker);
    }
    return result;
  } catch (e, s) {
    talker.error('[push:bg] enrich failed', e, s);
    return PushHandleResult.failed;
  } finally {
    if (client != null) {
      try {
        await client
            .dispose(closeDatabase: false)
            .timeout(const Duration(seconds: 3));
      } catch (e, s) {
        talker.warning('[push:bg] client dispose failed', e, s);
      }
    }
  }
}

Future<PushHandleResult> handlePushNotification({
  required PushNotification notification,
  required Client client,
  required FlutterLocalNotificationsPlugin localNotifications,
  required Talker talker,
  Duration lookupTimeout = const Duration(seconds: 30),
}) async {
  final eventId = notification.eventId;
  final roomId = notification.roomId;

  if (eventId == null || roomId == null) {
    return PushHandleResult.suppressed;
  }

  Event? event;
  try {
    event = await client
        .getEventByPushNotification(
          notification,
          storeInDatabase: true,
          returnNullIfSeen: true,
        )
        .timeout(lookupTimeout);
  } catch (e, s) {
    talker.error('[push] getEvent failed eventId=$eventId', e, s);
    return PushHandleResult.failed;
  }

  if (event == null) return PushHandleResult.suppressed;

  if (event.type == 'org.matrix.msc4075.rtc.notification') {
    await _showIncomingCall(
      event: event,
      roomId: roomId,
      client: client,
      talker: talker,
    );
    return PushHandleResult.shown;
  }

  try {
    final result = client.pushruleEvaluator.match(event);
    if (!result.notify) {
      return PushHandleResult.suppressed;
    }
  } catch (e, s) {
    talker.warning('[push] pushrule evaluation failed', e, s);
  }

  if (await _isMentionsOnlyRoom(roomId) &&
      event.type != EventTypes.Encrypted &&
      !_mentionsUser(event, client)) {
    return PushHandleResult.suppressed;
  }

  try {
    final body = await _buildBody(event);
    final title = _buildTitle(event);

    final payload = jsonEncode({'roomId': roomId, 'eventId': eventId});

    await localNotifications
        .show(
          id: roomNotificationId(roomId),
          title: title,
          body: body,
          notificationDetails: await _detailsForEvent(
            client: client,
            event: event,
            roomId: roomId,
            title: title,
            body: body,
            unreadCount: notification.counts?.unread,
            localNotifications: localNotifications,
            talker: talker,
          ),
          payload: payload,
        )
        .timeout(const Duration(seconds: 5));

    await _updateSummary(
      localNotifications: localNotifications,
      talker: talker,
    );
    return PushHandleResult.shown;
  } catch (e, s) {
    talker.error('[push] show notification failed eventId=$eventId', e, s);
    return PushHandleResult.failed;
  }
}

Future<void> _showIncomingCall({
  required Event event,
  required String roomId,
  required Client client,
  required Talker talker,
}) async {
  try {
    final room = client.getRoomById(roomId);
    final callkit = CallkitService(talker);
    await callkit.showIncoming(
      roomId: roomId,
      callerName:
          room?.getLocalizedDisplayname(ruMatrixLocalizations) ??
          'Входящий звонок',
    );
    final lifetimeMs = event.content['lifetime'] as int?;
    final deadline = DateTime.now().add(
      Duration(milliseconds: lifetimeMs ?? 30000),
    );
    final signaling = MatrixRtcSignaling(client, talker);
    while (DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(seconds: 2));
      try {
        await client.oneShotSync().timeout(const Duration(seconds: 8));
      } catch (_) {
        break;
      }
      final current = client.getRoomById(roomId);
      if (current == null) break;
      if (signaling.ownMembership(current) != null) break;
      final others = signaling
          .activeMembers(current)
          .where((m) => m.senderId != null && m.senderId != client.userID);
      if (others.isEmpty) {
        await callkit.endCall(roomId);
        break;
      }
    }
  } catch (e, s) {
    talker.error('[push] incoming call failed', e, s);
  }
}

Future<void> showFallbackNotification({
  required String roomId,
  required String eventId,
  required FlutterLocalNotificationsPlugin localNotifications,
  required Talker talker,
}) async {
  try {
    await localNotifications.show(
      id: roomNotificationId(roomId),
      title: 'Новое сообщение в ConvetChat',
      body: 'Откройте приложение, чтобы прочитать.',
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          PushConfig.androidChannelId,
          PushConfig.androidChannelName,
          channelDescription: PushConfig.androidChannelDescription,
          icon: '@mipmap/launcher_icon',
          importance: Importance.high,
          priority: Priority.max,
          category: AndroidNotificationCategory.message,
          groupKey: _notificationGroup,
        ),
        iOS: DarwinNotificationDetails(
          categoryIdentifier: PushConfig.iosCategoryId,
          threadIdentifier: roomId,
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode({'roomId': roomId, 'eventId': eventId}),
    );
    await _updateSummary(
      localNotifications: localNotifications,
      talker: talker,
    );
  } catch (e, s) {
    talker.error('[push] fallback notification failed', e, s);
  }
}

@pragma('vm:entry-point')
Future<void> notificationTapBackground(NotificationResponse response) async {
  DartPluginRegistrant.ensureInitialized();
  final talker = createTalker();
  try {
    await TalkerFileSink.init();
  } catch (_) {}
  final mainPort = IsolateNameServer.lookupPortByName(pushActionPortName);
  if (mainPort != null) {
    try {
      mainPort.send(serializeNotificationResponse(response));
    } catch (e, s) {
      talker.error('[push:tap:bg] forward failed', e, s);
    }
    return;
  }
  if (response.notificationResponseType !=
      NotificationResponseType.selectedNotificationAction) {
    return;
  }
  final actionId = response.actionId;
  if (actionId != markAsReadActionId &&
      actionId != replyActionId &&
      actionId != muteActionId) {
    return;
  }

  Map<String, dynamic>? data;
  final payload = response.payload;
  if (payload != null) {
    try {
      data = jsonDecode(payload) as Map<String, dynamic>;
    } catch (_) {}
  }
  final roomId = data?['roomId'] as String?;
  final eventId = data?['eventId'] as String?;
  if (roomId == null) {
    talker.warning('[push:tap:bg] no roomId in payload');
    return;
  }

  final localNotifications = FlutterLocalNotificationsPlugin();
  await _init(localNotifications, talker);

  Client? client;
  try {
    client = await ClientFactory.createClient().timeout(
      const Duration(seconds: 20),
    );
    if (!client.isLogged()) {
      talker.warning(
        '[push:tap] action=$actionId skipped: client not logged in',
      );
      return;
    }
    client
      ..backgroundSync = false
      ..syncPresence = PresenceType.offline;
    try {
      await client.abortSync();
    } catch (_) {}
    try {
      await client.roomsLoading?.timeout(const Duration(seconds: 15));
      await client.accountDataLoading?.timeout(const Duration(seconds: 15));
      await client.userDeviceKeysLoading?.timeout(const Duration(seconds: 15));
    } on TimeoutException catch (e, s) {
      talker.warning('[push:tap] rooms loading timeout', e, s);
    }
    final room = client.getRoomById(roomId);
    switch (actionId) {
      case replyActionId:
        final input = response.input?.trim();
        if (input == null || input.isEmpty) {
          talker.warning('[push:tap] reply skipped: empty input');
          break;
        }
        if (room == null) {
          talker.warning(
            '[push:tap] reply skipped: room not found roomId=$roomId',
          );
          break;
        }
        await room
            .sendTextEvent(
              input,
              parseCommands: false,
              displayPendingEvent: false,
            )
            .timeout(const Duration(seconds: 20));
        try {
          await _markRead(client, room, roomId, eventId, talker);
        } catch (e, s) {
          talker.warning('[push:tap] read after reply failed', e, s);
        }
      case muteActionId:
        await _muteRoom(client, room, roomId, talker);
      default:
        await _markRead(client, room, roomId, eventId, talker);
    }
  } on TimeoutException catch (e, s) {
    talker.error('[push:tap] action timeout actionId=$actionId', e, s);
  } catch (e, s) {
    talker.error('[push:tap] action failed actionId=$actionId', e, s);
  } finally {
    if (client != null) {
      try {
        await client
            .dispose(closeDatabase: false)
            .timeout(const Duration(seconds: 3));
      } catch (_) {}
    }
  }

  try {
    await _cancelRoom(roomId, localNotifications, talker);
    await _updateSummary(
      localNotifications: localNotifications,
      talker: talker,
    );
  } catch (e, s) {
    talker.warning('[push:tap] dismiss notification failed', e, s);
  }
}

Future<void> _muteRoom(
  Client client,
  Room? room,
  String roomId,
  Talker talker,
) async {
  if (room != null) {
    await room
        .setPushRuleState(PushRuleState.dontNotify)
        .timeout(const Duration(seconds: 10));
    return;
  }
  talker.warning(
    '[push:tap] room not found, applying direct pushrule mute roomId=$roomId',
  );
  await client
      .setPushRule(
        PushRuleKind.override,
        roomId,
        [],
        conditions: [
          PushCondition(
            kind: PushRuleConditions.eventMatch.name,
            key: 'room_id',
            pattern: roomId,
          ),
        ],
      )
      .timeout(const Duration(seconds: 10));
}

Future<void> _markRead(
  Client client,
  Room? room,
  String roomId,
  String? eventId,
  Talker talker,
) async {
  final targetEventId = eventId ?? room?.lastEvent?.eventId;
  if (targetEventId == null) {
    talker.warning(
      '[push:tap] markRead skipped: no target event roomId=$roomId',
    );
    return;
  }
  try {
    if (room != null) {
      await room
          .setReadMarker(targetEventId, mRead: targetEventId)
          .timeout(const Duration(seconds: 10));
      return;
    }
  } catch (e, s) {
    talker.warning(
      '[push:tap] room.setReadMarker failed, using client fallback',
      e,
      s,
    );
  }
  await client
      .setReadMarker(roomId, mFullyRead: targetEventId, mRead: targetEventId)
      .timeout(const Duration(seconds: 10));
}

Future<void> _cancelRoom(
  String roomId,
  FlutterLocalNotificationsPlugin localNotifications,
  Talker talker,
) async {
  try {
    await localNotifications.cancel(id: roomNotificationId(roomId));
  } catch (e, s) {
    talker.warning('[push] cancel room notification failed', e, s);
  }
}

Future<void> dismissRoomNotification({
  required String roomId,
  required FlutterLocalNotificationsPlugin localNotifications,
  required Talker talker,
}) async {
  if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) return;

  try {
    final id = roomNotificationId(roomId);

    if (!Platform.isAndroid) {
      await localNotifications.cancel(id: id);
      return;
    }

    final active = await localNotifications.getActiveNotifications();
    final hasOurs = active.any(
      (n) => n.id == id || n.id == _summaryNotificationId,
    );
    if (!hasOurs) return;

    await localNotifications.cancel(id: id);
    await _updateSummary(
      localNotifications: localNotifications,
      talker: talker,
    );
  } catch (e, s) {
    talker.warning('[push] cancel room notification failed', e, s);
  }
}

Future<void> _updateSummary({
  required FlutterLocalNotificationsPlugin localNotifications,
  required Talker talker,
}) async {
  if (kIsWeb || !Platform.isAndroid) return;
  try {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final rooms = (await localNotifications.getActiveNotifications())
        .where((n) => n.groupKey == _notificationGroup)
        .where((n) => n.id != _summaryNotificationId)
        .toList();

    if (rooms.isEmpty) {
      await localNotifications.cancel(id: _summaryNotificationId);
      return;
    }

    await localNotifications.show(
      id: _summaryNotificationId,
      title: 'ConvetChat',
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          PushConfig.androidChannelId,
          PushConfig.androidChannelName,
          channelDescription: PushConfig.androidChannelDescription,
          groupKey: _notificationGroup,
          setAsGroupSummary: true,
          styleInformation: InboxStyleInformation(
            rooms.map((n) => n.body ?? n.title ?? '').toList(),
          ),
          autoCancel: false,
          silent: true,
        ),
      ),
    );
  } catch (e, s) {
    talker.warning('[push] update summary notification failed', e, s);
  }
}

Future<void> _init(
  FlutterLocalNotificationsPlugin localNotifications,
  Talker talker,
) async {
  try {
    await localNotifications.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/launcher_icon'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    if (!kIsWeb && Platform.isAndroid) {
      final androidPlugin = localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await androidPlugin?.createNotificationChannel(
        AndroidNotificationChannel(
          PushConfig.androidChannelId,
          PushConfig.androidChannelName,
          description: PushConfig.androidChannelDescription,
          importance: Importance.high,
        ),
      );
    }
  } catch (e, s) {
    talker.error('[push] local notifications init failed', e, s);
  }
}

AndroidNotificationDetails _baseAndroidDetails() {
  return AndroidNotificationDetails(
    PushConfig.androidChannelId,
    PushConfig.androidChannelName,
    channelDescription: PushConfig.androidChannelDescription,
    icon: '@mipmap/launcher_icon',
    importance: Importance.high,
    priority: Priority.max,
    category: AndroidNotificationCategory.message,
    groupKey: _notificationGroup,
    actions: _messageActions,
  );
}

Future<NotificationDetails> _detailsForEvent({
  required Client client,
  required Event event,
  required String roomId,
  required String title,
  required String body,
  required int? unreadCount,
  required FlutterLocalNotificationsPlugin localNotifications,
  required Talker talker,
}) async {
  final iosDetails = DarwinNotificationDetails(
    categoryIdentifier: PushConfig.iosCategoryId,
    threadIdentifier: roomId,
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );

  if (kIsWeb || !Platform.isAndroid) {
    return NotificationDetails(android: _baseAndroidDetails(), iOS: iosDetails);
  }

  final senderName = event.senderFromMemoryOrFallback.calcDisplayname(
    i18n: ruMatrixLocalizations,
  );
  final newMessage = Message(
    body,
    event.originServerTs,
    Person(
      key: event.senderId,
      name: senderName,
      bot: event.messageType == MessageTypes.Notice,
    ),
  );

  MessagingStyleInformation? style;
  try {
    style = await localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.getActiveNotificationMessagingStyle(id: roomNotificationId(roomId));
    style?.messages?.add(newMessage);
  } catch (e, s) {
    talker.warning('[push] get messaging style failed', e, s);
    style = null;
  }

  style ??= MessagingStyleInformation(
    Person(key: client.userID, name: ruMatrixLocalizations.you),
    conversationTitle: event.room.isDirectChat ? null : title,
    groupConversation: !event.room.isDirectChat,
    messages: [newMessage],
  );

  final ticker = event.room.isDirectChat ? body : '$senderName: $body';

  return NotificationDetails(
    android: AndroidNotificationDetails(
      PushConfig.androidChannelId,
      PushConfig.androidChannelName,
      channelDescription: PushConfig.androidChannelDescription,
      icon: '@mipmap/launcher_icon',
      importance: Importance.high,
      priority: Priority.max,
      category: AndroidNotificationCategory.message,
      styleInformation: style,
      groupKey: _notificationGroup,
      shortcutId: roomId,
      ticker: ticker,
      when: event.originServerTs.millisecondsSinceEpoch,
      number: unreadCount,
      actions: _actionsForEventType(event.type),
    ),
    iOS: iosDetails,
  );
}

String _buildTitle(Event event) {
  final room = event.room;
  if (room.isDirectChat) {
    return event.senderFromMemoryOrFallback
        .calcDisplayname(i18n: ruMatrixLocalizations)
        .replaceAll('@', '');
  }
  return room.getLocalizedDisplayname(ruMatrixLocalizations);
}

Future<String> _buildBody(Event event) async {
  if (event.type == EventTypes.Encrypted) {
    return 'Новое сообщение';
  }
  if (event.type == PollEventContent.responseType) {
    return 'Голос в опросе';
  }
  if (event.type == EventTypes.RoomPinnedEvents) {
    return _pinPushLabel(event);
  }
  if (event.type == 'org.matrix.msc3401.call.member' ||
      event.type == 'org.matrix.msc4075.rtc.notification') {
    return 'Голосовой звонок';
  }
  final label = event
      .calcLocalizedBodyFallback(
        ruMatrixLocalizations,
        hideReply: true,
        hideEdit: true,
        plaintextBody: true,
        removeMarkdown: true,
        withSenderNamePrefix: false,
      )
      .trim();
  if (label.isEmpty) return 'Сообщение';
  return label;
}

String _pinPushLabel(Event event) {
  final pinned = event.content['pinned'];
  final hasPinned = pinned is Iterable && pinned.isNotEmpty;
  final own = event.senderId == event.room.client.userID;
  if (own) {
    return hasPinned ? 'Вы закрепили сообщение' : 'Вы открепили сообщение';
  }
  final name = event.senderFromMemoryOrFallback.calcDisplayname(
    i18n: ruMatrixLocalizations,
  );
  return '$name ${hasPinned ? 'закрепил сообщение' : 'открепил сообщение'}';
}
