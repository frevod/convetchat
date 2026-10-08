import 'package:convetchat/app/adaptive/adaptive_dialog.dart';
import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/platform_style.dart';
import 'package:convetchat/features/auth/domain/entities/auth_mode.dart';
import 'package:convetchat/features/auth/ui/bloc/auth_cubit.dart';
import 'package:convetchat/features/auth/ui/bloc/auth_state.dart';
import 'package:convetchat/features/auth/ui/pages/server_page_andr.dart';
import 'package:convetchat/features/auth/ui/pages/server_page_cup.dart';
import 'package:convetchat/features/auth/ui/widgets/auth_failure_listener.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class const ServerPage({super.key, required final AuthMode mode})
    extends StatelessWidget {
  static const _unsupportedLoginTitle = 'Сервер не поддерживает вход';
  static const _unsupportedRegisterTitle = 'Сервер не поддерживает регистрацию';
  static const _unsupportedLoginMessage =
      'Этот сервер не поддерживает вход через сайт. '
      'Укажите homeserver с поддержкой входа через браузер.';
  static const _unsupportedRegisterMessage =
      'Этот сервер не поддерживает регистрацию через сайт. '
      'Укажите homeserver с поддержкой регистрации через браузер.';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AuthCubit>(param1: mode),
      child: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) async {
          if (state is AuthSsoUnsupported) {
            await AdaptiveDialog.show<void>(
              context: context,
              title: mode == .register
                  ? _unsupportedRegisterTitle
                  : _unsupportedLoginTitle,
              subtitle: mode == .register
                  ? _unsupportedRegisterMessage
                  : _unsupportedLoginMessage,
              axis: .vertical,
              actions: const [
                AdaptiveDialogAction(
                  label: 'ОК',
                  isPrimary: true,
                  result: true,
                ),
              ],
            );
            if (!context.mounted) return;
            context.read<AuthCubit>().dismissSsoUnsupported();
          } else if (state is AuthAuthenticated) {
            context.go('/backup');
          }
        },
        child: AuthFailureListener(
          child: (getIt<PlatformStyle>().isCupertino)
              ? const ServerPageCup()
              : const ServerPageAndr(),
        ),
      ),
    );
  }
}
