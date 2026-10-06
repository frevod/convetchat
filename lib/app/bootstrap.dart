import 'dart:async';

import 'package:convetchat/app/app.dart';
import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/firebase/telemetry_service.dart';
import 'package:convetchat/core/logging/talker_file_sink.dart';
import 'package:convetchat/core/platform_info.dart';
import 'package:convetchat/core/push/push_notification_handler.dart';
import 'package:convetchat/core/push/push_service.dart';
import 'package:convetchat/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
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
