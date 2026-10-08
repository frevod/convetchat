import 'dart:async';
import 'dart:io';

import 'package:convetchat/app/app.dart';
import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/firebase/telemetry_service.dart';
import 'package:convetchat/features/call/data/datasources/callkit_service.dart';
import 'package:convetchat/features/call/data/datasources/incoming_call_watcher.dart';
import 'package:convetchat/features/call/data/datasources/pending_answer_store.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:go_router/go_router.dart';
import 'package:convetchat/core/logging/talker_file_sink.dart';
import 'package:convetchat/core/platform_info.dart';
import 'package:convetchat/core/push/push_notification_handler.dart';
import 'package:convetchat/core/push/push_service.dart';
import 'package:convetchat/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'package:matrix/matrix.dart';
import 'package:talker_flutter/talker_flutter.dart';

Future<void> bootstrap() async {
  await runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      FlutterError.onError = (details) {
        FlutterError.presentError(details);
      };

      await setupLocator();

      try {
        await _initFirebase();
      } catch (e) {
        getIt<Talker>().error('[bootstrap] Firebase init failed', e);
      }
      registerPushBackgroundHandler();

      try {
        await dotenv.load();
      } catch (e) {
        getIt<Talker>().error('[bootstrap] .env load failed', e);
      }

      await TalkerFileSink.init();

      if (PlatformInfos.isDesktop) {
        try {
          JustAudioMediaKit.ensureInitialized();
        } catch (e) {
          getIt<Talker>().error('[bootstrap] MediaKit init failed', e);
        }
      }

      runApp(const ConvetChatApp());

      await getIt<TelemetryService>().init();

      try {
        await getIt.getAsync<Client>().timeout(const Duration(seconds: 60));
      } on TimeoutException catch (e, s) {
        getIt<Talker>().error('[bootstrap] Client init timeout (60s)', e, s);
      }

      if (getIt.isReadySync<Client>()) {
        await getIt<PushService>().init();
        _initIncomingCalls();
        await _drainPendingAnswer();
      } else {
        getIt<Talker>().warning(
          '[bootstrap] Push init skipped: Client not ready',
        );
      }

      final talker = getIt<Talker>();
      final telemetry = getIt<TelemetryService>();

      FlutterError.onError = (details) {
        talker.error('Flutter framework error', details.exception, details.stack);
        telemetry.logError(
          details.exception,
          details.stack ?? StackTrace.current,
        );
      };

      WidgetsBinding.instance.platformDispatcher.onError = (error, stack) {
        talker.error('Uncaught platform error', error, stack);
        telemetry.logError(error, stack);
        return true;
      };
    },
    (error, stack) {
      try {
        getIt<Talker>().error('Uncaught zone error', error, stack);
      } catch (_) {
        debugPrint('Bootstrap error: $error');
      }
      try {
        getIt<TelemetryService>().logError(error, stack);
      } catch (_) {}
    },
  );
}

void _initIncomingCalls() {
  if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) return;
  final talker = getIt<Talker>();
  try {
    getIt<IncomingCallWatcher>().start();
  } catch (e) {
    talker.error('[bootstrap] incoming watcher start failed', e);
  }
  FlutterCallkitIncoming.acceptCallHandle((data) {
    final roomId =
        data['roomId'] as String? ??
        (data['extra'] is Map ? (data['extra'] as Map)['roomId'] as String? : null);
    final roomName =
        data['roomName'] as String? ??
        (data['extra'] is Map
            ? (data['extra'] as Map)['roomName'] as String?
            : null) ??
        '';
    if (roomId == null || roomId.isEmpty) return;
    unawaited(_stashAndOpen(roomId, roomName));
  });
  try {
    getIt<CallkitService>().events.listen((event) {
      switch (event) {
        case CallEventActionCallAccept():
          final extra = event.callKitParams.extra;
          final roomId = extra?['roomId'] as String?;
          final roomName = extra?['roomName'] as String? ?? '';
          if (roomId == null) return;
          unawaited(_stashAndOpen(roomId, roomName));
        case CallEventActionCallDecline():
        case CallEventActionCallEnded():
        case CallEventActionCallTimeout():
          unawaited(PendingAnswerStore().clear());
        default:
          break;
      }
    });
  } catch (e) {
    talker.error('[bootstrap] callkit listener failed', e);
  }
}

String? _lastOpenedRoom;
DateTime _lastOpenedAt = DateTime.fromMillisecondsSinceEpoch(0);

Future<void> _stashAndOpen(String roomId, String roomName) async {
  final talker = getIt<Talker>();
  try {
    await PendingAnswerStore().save(roomId, roomName);
  } catch (e) {
    talker.error('[bootstrap] stash pending answer failed', e);
  }
  if (!getIt.isRegistered<GoRouter>()) return;
  final now = DateTime.now();
  if (_lastOpenedRoom == roomId &&
      now.difference(_lastOpenedAt).inSeconds < 10) {
    return;
  }
  _lastOpenedRoom = roomId;
  _lastOpenedAt = now;
  try {
    getIt<GoRouter>().push(
      '/call/$roomId?mode=answer',
      extra: {'roomId': roomId, 'roomName': roomName},
    );
  } catch (e) {
    talker.error('[bootstrap] open call from callkit failed', e);
  }
}

Future<void> _drainPendingAnswer() async {
  final talker = getIt<Talker>();
  try {
    final pending = await PendingAnswerStore().drain();
    if (pending == null) return;
    if (!getIt.isRegistered<GoRouter>()) return;
    getIt<GoRouter>().push(
      '/call/${pending.roomId}?mode=answer',
      extra: {'roomId': pending.roomId, 'roomName': pending.roomName},
    );
  } catch (e) {
    talker.error('[bootstrap] drain pending answer failed', e);
  }
}

Future<void> _initFirebase() async {
  if (!PlatformInfos.supportsFirebase) return;
  if (Firebase.apps.isNotEmpty) {
    return;
  }
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on UnsupportedError {
    return;
  } catch (e) {
    if (!e.toString().contains('duplicate-app')) {
      rethrow;
    }
  }
}
