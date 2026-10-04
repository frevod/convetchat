import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:convetchat/core/logging/talker.dart';
import 'package:convetchat/core/matrix/client_factory.dart';
import 'package:convetchat/core/push/push_config.dart';
import 'package:convetchat/core/matrix/ru_matrix_localizations.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:matrix/matrix.dart';
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

void registerPushBackgroundHandler() {
  if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) return;
  try {
    FirebaseMessaging.onBackgroundMessage(onBackgroundMessage);
  } catch (_) {}
}

@pragma('vm:entry-point')
Future<void> onBackgroundMessage(RemoteMessage message) async {
  final data = message.data;
  final eventId = data['event_id'] as String?;
  final roomId = data['room_id'] as String?;

  if (eventId == null || roomId == null) {
    return;
  }

  final talker = createTalker();
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
    talker.warning('[push:bg] Обогащение не успело — базовое уведомление');
    unawaited(showFallback());
  });

  try {
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
    talker.warning('[push:bg] Бюджет $_backgroundEnrichBudget исчерпан');
  } catch (e, s) {
    settled = true;
    await showFallback();
    talker.error('[push:bg] Неожиданная ошибка', e, s);
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
      talker.warning('[push:bg] Клиент не залогинен, оставляем базовый пуш');
      return PushHandleResult.failed;
    }

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
    talker.error('[push:bg] Ошибка обогащения, оставляем базовый пуш', e, s);
    return PushHandleResult.failed;
  } finally {
    if (client != null) {
      try {
        await client.dispose(closeDatabase: false).timeout(
          const Duration(seconds: 3),
        );
      } catch (e, s) {
        talker.warning('[push:bg] Не удалось отпустить клиент', e, s);
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
    talker.error('[push] Не удалось получить ивент $eventId', e, s);
    return PushHandleResult.failed;
  }

  if (event == null) return PushHandleResult.suppressed;

  try {
    final result = client.pushruleEvaluator.match(event);
    if (!result.notify) {
      return PushHandleResult.suppressed;
    }
  } catch (e, s) {
    talker.warning('[push] Ошибка оценки push-правил', e, s);
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
    talker.error('[push] Не удалось показать уведомление $eventId', e, s);
    return PushHandleResult.failed;
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
        android: _baseAndroidDetails(),
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
    talker.error('[push] Упало даже базовое уведомление', e, s);
  }
}

@pragma('vm:entry-point')
Future<void> notificationTapBackground(NotificationResponse response) async {
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
  if (roomId == null || eventId == null) return;

  final talker = createTalker();
  final localNotifications = FlutterLocalNotificationsPlugin();
  await _init(localNotifications, talker);

  Client? client;
  try {
    client = await ClientFactory.createClient().timeout(
      const Duration(seconds: 20),
    );
    if (!client.isLogged()) {
      talker.warning('[push:tap] Клиент не залогинен, действие $actionId');
      return;
    }
    final room = await _resolveRoom(client, roomId, talker);
    switch (actionId) {
      case replyActionId:
        final input = response.input?.trim();
        if (input != null && input.isNotEmpty) {
          if (room != null) {
            await room
                .sendTextEvent(input, parseCommands: false)
                .timeout(const Duration(seconds: 15));
          } else {
            talker.warning('[push:tap] Нет комнаты $roomId, ответ не отправлен');
          }
        }
        await _markRead(client, roomId, eventId, talker);
      case muteActionId:
        await _muteRoom(client, room, roomId, talker);
        await _markRead(client, roomId, eventId, talker);
      default:
        await _markRead(client, roomId, eventId, talker);
    }
  } on TimeoutException catch (e, s) {
    talker.error('[push:tap] Таймаут действия $actionId', e, s);
  } catch (e, s) {
    talker.error('[push:tap] Не удалось обработать действие $actionId', e, s);
  } finally {
    if (client != null) {
      try {
        await client.dispose(closeDatabase: false).timeout(
          const Duration(seconds: 3),
        );
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
    talker.warning('[push:tap] Не удалось снять уведомление', e, s);
  }
}

Future<Room?> _resolveRoom(Client client, String roomId, Talker talker) async {
  try {
    final cached = client.getRoomById(roomId);
    if (cached != null) return cached;
    try {
      final fromDb = await client.database
          .getSingleRoom(client, roomId)
          .timeout(const Duration(seconds: 5));
      if (fromDb != null) return fromDb;
    } catch (e, s) {
      talker.warning('[push:tap] Не удалось загрузить комнату из базы', e, s);
    }
    return Room(id: roomId, client: client);
  } catch (e, s) {
    talker.warning('[push:tap] Не удалось резолвнуть комнату', e, s);
    return null;
  }
}

Future<void> _muteRoom(
  Client client,
  Room? room,
  String roomId,
  Talker talker,
) async {
  try {
    if (room != null) {
      await room
          .setPushRuleState(PushRuleState.dontNotify)
          .timeout(const Duration(seconds: 10));
      return;
    }
  } catch (e, s) {
    talker.warning('[push:tap] Мьют через Room не удался, пробую напрямую', e, s);
  }
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
  String roomId,
  String eventId,
  Talker talker,
) async {
  try {
    await client
        .setReadMarker(roomId, mFullyRead: eventId, mReadPrivate: eventId)
        .timeout(const Duration(seconds: 10));
  } catch (e, s) {
    talker.warning('[push:tap] Не удалось отметить прочитанным', e, s);
    rethrow;
  }
}

Future<void> _cancelRoom(
  String roomId,
  FlutterLocalNotificationsPlugin localNotifications,
  Talker talker,
) async {
  try {
    await localNotifications.cancel(id: roomNotificationId(roomId));
  } catch (e, s) {
    talker.warning('[push] Не удалось снять уведомление комнаты', e, s);
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
    talker.warning('[push] Не удалось снять уведомление комнаты', e, s);
  }
}

Future<void> _updateSummary({
  required FlutterLocalNotificationsPlugin localNotifications,
  required Talker talker,
}) async {
  if (kIsWeb || !Platform.isAndroid) return;
  try {
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
    talker.warning('[push] Не удалось обновить сводное уведомление', e, s);
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
    talker.error(
      '[push] Не удалось инициализировать локальные уведомления',
      e,
      s,
    );
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
    talker.warning('[push] Не удалось получить стиль переписки', e, s);
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
      actions: _messageActions,
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
