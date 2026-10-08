import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/errors/auth_errors.dart';
import 'package:convetchat/core/platform_style.dart';
import 'package:convetchat/core/push/push_service.dart';
import 'package:convetchat/features/auth/domain/entities/auth_mode.dart';
import 'package:convetchat/features/auth/domain/repositories/auth_repository.dart';
import 'package:convetchat/features/auth/ui/pages/login_callback_page_andr.dart';
import 'package:convetchat/features/auth/ui/pages/login_callback_page_cup.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:talker_flutter/talker_flutter.dart';

class const LoginCallbackPage({super.key, final String? token})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (getIt<PlatformStyle>().isCupertino) {
      return LoginCallbackPageCup(token: token);
    }
    return LoginCallbackPageAndr(token: token);
  }
}

Future<String?> completeTokenLogin(BuildContext context, String? token) async {
  if (token == null || token.isEmpty) {
    return 'Ссылка для входа недействительна';
  }
  try {
    await getIt<AuthRepository>().loginWithToken(token);
    try {
      await getIt<PushService>().refreshPusher();
    } catch (e, s) {
      getIt<Talker>().error('[auth] pusher registration failed', e, s);
    }
    if (!context.mounted) return null;
    context.go('/backup');
    return null;
  } catch (e, s) {
    getIt<Talker>().error('[auth] callback login failed', e, s);
    return authErrorMessage(e);
  }
}

Future<String?> startDefaultServerSso(
  BuildContext context,
  AuthMode mode,
) async {
  try {
    final repository = getIt<AuthRepository>();
    await repository.checkHomeserver('convet.xyz');
    await repository.loginWithSso(mode: mode);
    try {
      await getIt<PushService>().refreshPusher();
    } catch (e, s) {
      getIt<Talker>().error('[auth] pusher registration failed', e, s);
    }
    if (!context.mounted) return null;
    context.go('/backup');
    return null;
  } catch (e, s) {
    getIt<Talker>().error('[auth] default sso failed', e, s);
    return authErrorMessage(e);
  }
}
