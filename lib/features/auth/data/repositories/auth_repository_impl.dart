import 'package:convetchat/core/matrix/client_factory.dart';
import 'package:convetchat/core/matrix/session_backup.dart';
import 'package:convetchat/core/platform_info.dart';
import 'package:convetchat/features/auth/domain/entities/auth_mode.dart';
import 'package:convetchat/features/auth/domain/exceptions/sso_cancelled_exception.dart';
import 'package:convetchat/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:matrix/matrix.dart';

class AuthRepositoryImpl(final Client _client) implements AuthRepository {

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

  @override
  Future<void> logout() async {
    await deleteSessionBackup(ClientFactory.clientName);
    await _client.logout();
    _serverName = null;
  }

  static const ssoCallbackScheme = 'convetchat';

  static const _desktopCallbackUrl = 'http://localhost:3001';

  @override
  Future<void> loginWithSso({required AuthMode mode}) async {
    final homeserver = _client.homeserver;
    if (homeserver == null) {
      throw const SsoCancelledException();
    }
    final desktop = PlatformInfos.isDesktop;
    final url = homeserver.replace(
      path: '/_matrix/client/v3/login/sso/redirect',
      queryParameters: {
        'redirectUrl': desktop
            ? '$_desktopCallbackUrl/login'
            : '$ssoCallbackScheme:/login',
        'action': mode == .register ? 'register' : 'login',
      },
    );
    late final String callback;
    try {
      callback = await FlutterWebAuth2.authenticate(
        url: url.toString(),
        callbackUrlScheme: desktop ? _desktopCallbackUrl : ssoCallbackScheme,
        options: FlutterWebAuth2Options(useWebview: !desktop),
      );
    } on PlatformException catch (e) {
      if (e.code == 'CANCELED') throw const SsoCancelledException();
      rethrow;
    }

    final token = Uri.parse(callback).queryParameters['loginToken'];
    if (token == null || token.isEmpty) {
      throw const SsoCancelledException();
    }
    await loginWithToken(token);
  }

  @override
  Future<void> loginWithToken(String token) async {
    await _client.login(
      LoginType.mLoginToken,
      token: token,
      initialDeviceDisplayName: 'ConvetChat',
      refreshToken: true,
    );
    await storeSessionBackup(_client);
  }
}
