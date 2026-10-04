import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_vodozemac/flutter_vodozemac.dart' as vod;
import 'package:matrix/matrix.dart';

import 'matrix_database_builder.dart';
import 'session_backup.dart';

class ClientFactory() {
  static const String clientName = 'convetchat';

  static bool _vodozemacReady = false;
  static Future<void>? _vodozemacFlight;

  static Future<void> ensureVodozemac() async {
    if (_vodozemacReady || kIsWeb) return;
    final flight = _vodozemacFlight;
    if (flight != null) {
      await flight;
      return;
    }
    final future = vod.init().timeout(const Duration(seconds: 15));
    _vodozemacFlight = future;
    try {
      await future;
      _vodozemacReady = true;
      Logs().d('vodozemac готов');
    } catch (e, s) {
      Logs().e('vodozemac init failed', e, s);
      rethrow;
    } finally {
      _vodozemacFlight = null;
    }
  }

  static Future<Client> createClient() async {
    await ensureVodozemac();

    final client = Client(
      clientName,
      database: await buildMatrixDatabase(clientName),
      verificationMethods: {
        .numbers,
        if (kIsWeb ||
            defaultTargetPlatform == .android ||
            defaultTargetPlatform == .iOS ||
            defaultTargetPlatform == .linux)
          .emoji,
      },

      supportedLoginTypes: {
        AuthenticationTypes.password,
        AuthenticationTypes.sso,
        AuthenticationTypes.token,
      },
      nativeImplementations: (kIsWeb
          ? NativeImplementations.dummy
          : NativeImplementationsIsolate(
              compute,
              vodozemacInit: ensureVodozemac,
            )),
      logLevel: kDebugMode ? .debug : .warning,
      defaultNetworkRequestTimeout: const Duration(minutes: 1),

      shareKeysWith: .all,
      enableDehydratedDevices: false,
    );

    try {
      await client.init(
        waitForFirstSync: false,
        waitUntilLoadCompletedLoaded: false,
      );
      if (client.isLogged()) await storeSessionBackup(client);
    } catch (e, s) {
      Logs().e('Client init failed, пробую бэкап сессии', e, s);
      try {
        await restoreSessionBackup(client);
      } catch (e, s) {
        Logs().e('Бэкапа нет, продолжаем без входа', e, s);
      }
    }

    client.onSessionCleared.stream.listen((_) async {
      try {
        await deleteSessionBackup(client.clientName);
      } catch (_) {}
    });

    return client;
  }
}
