import 'package:convetchat/app/adaptive/adaptive_dialog.dart';
import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/platform_style.dart';
import 'package:convetchat/features/auth/ui/bloc/auth_cubit.dart';
import 'package:convetchat/features/auth/ui/bloc/auth_state.dart';
import 'package:convetchat/features/auth/ui/pages/server_page_andr.dart';
import 'package:convetchat/features/auth/ui/pages/server_page_cup.dart';
import 'package:convetchat/features/auth/ui/widgets/auth_failure_listener.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class const ServerPage({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AuthCubit>(),
      child: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) async {
          if (state is AuthServerVerified) {
            context.push('/login');
          } else if (state is AuthAuthenticated) {
            context.go('/backup');
          } else if (state is AuthSsoAvailable) {
            final confirmed = await AdaptiveDialog.confirm(
              axis: .vertical,
              context: context,
              title: 'Продолжить на сайте?',
              message:
                  'Этот сервер поддерживает вход на сайте. '
                  'Перейти на сайт или продолжить в приложении?',
              confirmLabel: 'На сайте',
              cancelLabel: 'В приложении',
            );
            if (!context.mounted) return;
            if (confirmed) {
              context.read<AuthCubit>().loginWithSso();
            } else {
              context.read<AuthCubit>().usePasswordInstead();
            }
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
