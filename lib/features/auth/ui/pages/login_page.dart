import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/platform_style.dart';
import 'package:convetchat/features/auth/ui/bloc/auth_cubit.dart';
import 'package:convetchat/features/auth/ui/bloc/auth_state.dart';
import 'package:convetchat/features/auth/ui/pages/login_page_andr.dart';
import 'package:convetchat/features/auth/ui/pages/login_page_cup.dart';
import 'package:convetchat/features/auth/ui/widgets/auth_failure_listener.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class const LoginPage({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AuthCubit>(),
      child: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            context.go('/backup');
          }
        },
        child: AuthFailureListener(
          child: (getIt<PlatformStyle>().isCupertino)
              ? const LoginPageCup()
              : const LoginPageAndr(),
        ),
      ),
    );
  }
}
