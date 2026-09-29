import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_vodozemac/flutter_vodozemac.dart' as vod;
import 'package:matrix/matrix.dart';

import 'matrix_database_builder.dart';
import 'session_backup.dart';

class ClientFactory() {
  static const String clientName = 'convetchat';

  static Future<Client> createClient() async {
    if (!kIsWeb) {
      await vod.init().timeout(const Duration(seconds: 15));
    }

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
              vodozemacInit: () => vod.init(),
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
      Logs().i('Client init: isLogged=${client.isLogged()}');
      if (client.isLogged()) await storeSessionBackup(client);
    } catch (e, s) {
      Logs().e('Client init failed, пробую бэкап сессии', e, s);
      try {
        await restoreSessionBackup(client);
        Logs().i(
          'Сессия восстановлена из бэкапа: isLogged=${client.isLogged()}',
        );
      } catch (e, s) {
        Logs().e('Бэкапа нет, продолжаем без входа', e, s);
      }
    }

    return client;
  }
}
