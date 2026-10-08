import 'dart:async';

import 'package:convetchat/core/presence/presence_mode.dart';
import 'package:convetchat/features/settings/data/repositories/security_repository_impl.dart';
import 'package:convetchat/features/settings/domain/repositories/presence_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_vodozemac/flutter_vodozemac.dart' as vod;
import 'package:matrix/matrix.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'matrix_database_builder.dart';
import 'session_backup.dart';

class ClientFactory() {
  static const String clientName = 'convetchat';
  static const String experimentalDehydratedDevicesKey =
      'experimental_dehydrated_devices';

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
      Logs().d('vodozemac ready');
    } catch (e, s) {
      Logs().e('vodozemac init failed', e, s);
      rethrow;
    } finally {
      _vodozemacFlight = null;
    }
  }

  static Future<bool> experimentalDehydratedDevicesEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(experimentalDehydratedDevicesKey) ?? true;
    } catch (_) {
      return true;
    }
  }

  static Future<void> _applyStoredPresence(Client client) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mode = PresenceMode.fromName(
        prefs.getString(PresenceRepository.storageKey),
      );
      if (mode == PresenceMode.online) return;
      client.syncPresence = mode.presenceType;
    } catch (_) {}
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
      importantStateEvents: {'org.matrix.msc3401.call.member'},

      shareKeysWith: await SecurityRepositoryImpl.restoredShareKeysMode(),
      enableDehydratedDevices: await experimentalDehydratedDevicesEnabled(),
    );

    try {
      await client.init(
        waitForFirstSync: false,
        waitUntilLoadCompletedLoaded: false,
      );
      await _applyStoredPresence(client);
      if (client.isLogged()) await storeSessionBackup(client);
    } catch (e, s) {
      Logs().e('Client init failed, restoring session backup', e, s);
      try {
        await restoreSessionBackup(client);
        Logs().d('Session restored from backup');
      } catch (e, s) {
        Logs().e('No session backup, continuing logged out', e, s);
      }
    }

    client.onSessionCleared.stream.listen((reason) async {
      try {
        if (reason != SessionClearReason.logout) return;
        await deleteSessionBackup(client.clientName);
      } catch (_) {}
    });

    return client;
  }
}
