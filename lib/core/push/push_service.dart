import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/push/push_config.dart';
import 'package:convetchat/core/push/push_notification_handler.dart';
import 'package:convetchat/core/utils/safe_text.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:matrix/matrix.dart';
import 'package:talker_flutter/talker_flutter.dart';

class PushService(final Client _client, final Talker _talker) {
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? _fcmToken;

  String? get fcmToken => _fcmToken;

  bool get notificationsEnabled => _fcmToken != null;

  Future<void> init() async {
    if (Platform.isAndroid || Platform.isIOS) {
      await _initLocalNotifications();
      await _initFirebaseMessaging();
    }
  }

  Future<void> refreshPusher() async {
    if (_fcmToken == null) return;
    await _setupPusher(gatewayUrl: PushConfig.gatewayUrl, token: _fcmToken);
  }

  Future<void> removePusher() async {
    try {
      final pushers = await _client.getPushers();
      if (pushers == null) return;
      for (final pusher in pushers) {
        if (pusher.appId.startsWith(PushConfig.appIdPrefix)) {
          await _client.deletePusher(pusher);
        }
      }
    } catch (e, s) {
      if (e is MatrixException && e.error == MatrixError.M_UNKNOWN_TOKEN) {
        _talker.warning('[push] Токен недействителен — удалять нечего');
      } else {
        _talker.error('[push] Ошибка удаления пушера', e, s);
      }
    }
  }

  Future<void> dismissForRoom(String roomId) async {
    await dismissRoomNotification(
      roomId: roomId,
      localNotifications: _localNotifications,
      talker: _talker,
    );
  }

  bool _isRoomVisible(String roomId) {
    try {
      final lifecycle = WidgetsBinding.instance.lifecycleState;
      if (lifecycle != AppLifecycleState.resumed &&
          lifecycle != AppLifecycleState.inactive) {
        return false;
      }
      final segments = getIt<GoRouter>()
          .routerDelegate
          .currentConfiguration
          .uri
          .pathSegments;
      if (segments.length < 2 || segments.first != 'chat') return false;
      return segments[1] == roomId;
    } catch (_) {
      return false;
    }
  }

  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/launcher_icon',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    if (Platform.isAndroid) {
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            PushConfig.androidChannelId,
            PushConfig.androidChannelName,
            description: PushConfig.androidChannelDescription,
            importance: Importance.high,
          ),
        );
        await androidPlugin.requestNotificationsPermission();
      }
    }
  }

  Future<void> _initFirebaseMessaging() async {
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      _fcmToken = newToken;
      await _setupPusher(gatewayUrl: PushConfig.gatewayUrl, token: newToken);
    });

    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpened);

    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) _onMessageOpened(message);
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final data = message.data;
      final remoteNotification = message.notification;

      final eventId = data['event_id'] as String?;
      final roomId = data['room_id'] as String?;

      if (roomId != null && _isRoomVisible(roomId)) return;

      if (eventId != null && roomId != null) {
        try {
          final notification = PushNotification.fromJson(data);
          final result = await handlePushNotification(
            notification: notification,
            client: _client,
            localNotifications: _localNotifications,
            talker: _talker,
          );
          if (result == PushHandleResult.failed) {
            await showFallbackNotification(
              roomId: roomId,
              eventId: eventId,
              localNotifications: _localNotifications,
              talker: _talker,
            );
          }
        } catch (e, s) {
          _talker.error('[push:fg] Ошибка обработки foreground', e, s);
        }
        return;
      }

      final title =
          remoteNotification?.title ??
          data['title'] as String? ??
          data['alert'] as String?;
      final body =
          remoteNotification?.body ??
          data['body'] as String? ??
          data['message'] as String?;
      if (title != null || body != null) {
        try {
          await _showSimpleNotification(
            title: title ?? 'ConvetChat',
            body: body ?? 'Тестовое уведомление',
            roomId: roomId,
            eventId: eventId,
          );
        } catch (e, s) {
          _talker.error('[push:fg] Ошибка показа тестового пуша', e, s);
        }
        return;
      }

      _talker.warning('[push:fg] data is empty, skip');
    });

    if (Platform.isIOS) {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      for (var i = 0; i < 10; i++) {
        try {
          final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
          if (apnsToken != null) break;
        } catch (_) {}
        await Future<void>.delayed(const Duration(seconds: 1));
      }
    }

    try {
      _fcmToken = await FirebaseMessaging.instance.getToken();
    } catch (e, s) {
      _talker.error('[push] Не удалось получить FCM-токен', e, s);
      return;
    }
    if (_fcmToken == null) {
      _talker.warning('[push] FCM-токен null — пушер не зарегистрирован');
      return;
    }

    await _setupPusher(gatewayUrl: PushConfig.gatewayUrl, token: _fcmToken);
  }

  Future<void> _setupPusher({
    required String gatewayUrl,
    required String? token,
  }) async {
    if (token == null) {
      _talker.warning('[push] Нет токена — пушер не зарегистрирован');
      return;
    }

    final deviceId = _client.deviceID ?? 'unknown';
    var appId = sanitizeForText('${PushConfig.appIdPrefix}.$deviceId');
    if (appId.runes.length > 64) {
      appId = String.fromCharCodes(appId.runes.take(64));
    }

    for (var attempt = 1; attempt <= 3; attempt++) {
      if (_client.userID != null && _client.isLogged()) break;
      await Future<void>.delayed(const Duration(seconds: 2));
    }
    if (_client.userID == null || !_client.isLogged()) {
      _talker.warning('[push] Пропуск регистрации пушера: нет сессии');
      return;
    }

    try {
      final desired = Pusher(
        pushkey: token,
        appId: appId,
        appDisplayName: 'ConvetChat',
        deviceDisplayName: 'Mobile',
        lang: 'ru',
        data: PusherData(
          url: Uri.parse(gatewayUrl),
          format: PushConfig.formatEventIdOnly,
          additionalProperties: {
            'client_name': _client.clientName,
            'data_message': true,
          },
        ),
        kind: 'http',
      );

      final existing = await _client.getPushers();
      if (existing != null) {
        for (final p in existing) {
          if (p.appId != appId) continue;
          if (_pusherMatches(p, desired)) return;
          await _client.deletePusher(p);
        }
      }

      await _client.postPusher(desired, append: true);
    } catch (e, s) {
      if (e is MatrixException && e.error == MatrixError.M_UNKNOWN_TOKEN) {
        _talker.warning(
          '[push] Токен недействителен — пушер не зарегистрирован',
        );
      } else if (e is http.ClientException) {
        _talker.warning('[push] Регистрация пушера отложена: ${e.message}');
      } else {
        _talker.error('[push] Ошибка регистрации пушера: $e', e, s);
      }
    }
  }

  bool _pusherMatches(Pusher current, Pusher desired) {
    final a = current.data;
    final b = desired.data;
    if (current.pushkey != desired.pushkey) return false;
    if (current.kind != desired.kind) return false;
    if (current.appDisplayName != desired.appDisplayName) return false;
    if (current.deviceDisplayName != desired.deviceDisplayName) return false;
    if (current.lang != desired.lang) return false;
    if (a.url != b.url) return false;
    if (a.format != b.format) return false;
    if (a.additionalProperties.length != b.additionalProperties.length) {
      return false;
    }
    for (final entry in b.additionalProperties.entries) {
      if (a.additionalProperties[entry.key] != entry.value) return false;
    }
    return true;
  }

  void _onMessageOpened(RemoteMessage message) {
    final roomId = message.data['room_id'] as String?;
    final eventId = message.data['event_id'] as String?;
    if (roomId != null) {
      try {
        _openRoom(roomId, eventId);
      } catch (e) {
        _talker.error('[push] Ошибка навигации по тапу', e);
      }
    }
  }

  void _openRoom(String roomId, String? eventId) {
    final router = getIt<GoRouter>();
    final location = '/chat/$roomId';

    if (router.canPop()) {
      unawaited(router.push(location, extra: eventId));
      return;
    }

    router.go('/chats');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (getIt.isReadySync<GoRouter>()) {
        unawaited(router.push(location, extra: eventId));
      }
    });
  }

  Future<void> _showSimpleNotification({
    required String title,
    required String body,
    String? roomId,
    String? eventId,
  }) async {
    final payload = jsonEncode({
      // ignore: use_null_aware_elements
      if (roomId != null) 'roomId': roomId,
      // ignore: use_null_aware_elements
      if (eventId != null) 'eventId': eventId,
    });
    await _localNotifications.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          PushConfig.androidChannelId,
          PushConfig.androidChannelName,
          channelDescription: PushConfig.androidChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/launcher_icon',
        ),
        iOS: DarwinNotificationDetails(
          categoryIdentifier: PushConfig.iosCategoryId,
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload.isEmpty ? null : payload,
    );
  }

  void _onNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null) return;

    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      final roomId = data['roomId'] as String?;
      final eventId = data['eventId'] as String?;
      if (roomId == null) return;
      final actionId = response.actionId;
      if (actionId == markAsReadActionId ||
          actionId == replyActionId ||
          actionId == muteActionId) {
        unawaited(_handleTapAction(response, roomId, eventId));
        return;
      }
      _openRoom(roomId, eventId);
    } catch (e) {
      _talker.error('[push] Ошибка обработки тапа по уведомлению', e);
    }
  }

  Future<void> _handleTapAction(
    NotificationResponse response,
    String roomId,
    String? eventId,
  ) async {
    try {
      final room =
          _client.getRoomById(roomId) ?? Room(id: roomId, client: _client);
      switch (response.actionId) {
        case replyActionId:
          final input = response.input?.trim();
          if (input != null && input.isNotEmpty) {
            await room
                .sendTextEvent(input, parseCommands: false)
                .timeout(const Duration(seconds: 15));
          }
          if (eventId != null) {
            await _client
                .setReadMarker(roomId, mFullyRead: eventId, mReadPrivate: eventId)
                .timeout(const Duration(seconds: 10));
          }
        case muteActionId:
          try {
            await room
                .setPushRuleState(PushRuleState.dontNotify)
                .timeout(const Duration(seconds: 10));
          } catch (_) {
            await _client
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
          if (eventId != null) {
            try {
              await _client
                  .setReadMarker(
                    roomId,
                    mFullyRead: eventId,
                    mReadPrivate: eventId,
                  )
                  .timeout(const Duration(seconds: 10));
            } catch (_) {}
          }
        default:
          if (eventId != null) {
            await _client
                .setReadMarker(roomId, mFullyRead: eventId, mReadPrivate: eventId)
                .timeout(const Duration(seconds: 10));
          }
      }
    } catch (e, st) {
      _talker.error('[push] Ошибка действия из уведомления', e, st);
    } finally {
      try {
        await dismissForRoom(roomId);
      } catch (e) {
        _talker.error('[push] Не удалось снять уведомление', e);
      }
    }
  }

  void dispose() {}
}
