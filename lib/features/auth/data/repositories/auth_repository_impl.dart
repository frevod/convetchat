import 'dart:math';

import 'package:convetchat/core/matrix/client_factory.dart';
import 'package:convetchat/core/matrix/session_backup.dart';
import 'package:convetchat/features/auth/domain/exceptions/sso_cancelled_exception.dart';
import 'package:convetchat/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:matrix/matrix.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthRepositoryImpl(final Client _client) implements AuthRepository {
  static const _deviceIdKey = 'convetchat_device_id';
  static const _deviceIdChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

  String? _serverName;

  @override
  String? get serverName => _serverName;

  @override
  Future<void> checkHomeserver(String homeserver) async {
    var input = homeserver.trim();
    if (!input.contains('://')) {
      input = 'https://$input';
    }
    final serverUri = Uri.parse(input);

    final result = await _client.checkHomeserver(serverUri);

    _serverName = serverUri.hasPort
        ? '${serverUri.host}:${serverUri.port}'
        : serverUri.host;

    if (!result.$3.any((flow) => flow.type == AuthenticationTypes.sso)) {
      throw const SsoNotSupportedException();
    }
  }

  Future<String> _stableDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_deviceIdKey);
    if (stored != null && stored.isNotEmpty) return stored;
    final random = Random.secure();
    final deviceId = List.generate(
      10,
      (_) => _deviceIdChars[random.nextInt(_deviceIdChars.length)],
    ).join();
    await prefs.setString(_deviceIdKey, deviceId);
    return deviceId;
  }

  @override
  Future<void> logout() async {
    await deleteSessionBackup(ClientFactory.clientName);
    await _client.logout();
    _serverName = null;
  }

  static const ssoCallbackScheme = 'convetchat';

  @override
  Future<void> loginWithSso() async {
    final homeserver = _client.homeserver;
    if (homeserver == null) {
      throw const SsoCancelledException();
    }
    final url = homeserver.replace(
      path: '/_matrix/client/v3/login/sso/redirect',
      queryParameters: {
        'redirectUrl': '$ssoCallbackScheme:/login',
        'action': 'login',
      },
    );
    late final String callback;
    try {
      callback = await FlutterWebAuth2.authenticate(
        url: url.toString(),
        callbackUrlScheme: ssoCallbackScheme,
      );
    } on PlatformException catch (e) {
      if (e.code == 'CANCELED') throw const SsoCancelledException();
      rethrow;
    }

    final token = Uri.parse(callback).queryParameters['loginToken'];
    if (token == null || token.isEmpty) {
      throw const SsoCancelledException();
    }
    await _client.login(
      LoginType.mLoginToken,
      token: token,
      deviceId: await _stableDeviceId(),
      initialDeviceDisplayName: 'ConvetChat',
    );
    await storeSessionBackup(_client);
  }
}
