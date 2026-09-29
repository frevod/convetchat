import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/adaptive/adaptive_buttons.dart';
import '../../../../app/adaptive/adaptive_loading_indicator.dart';
import '../bloc/auth_cubit.dart';
import '../bloc/auth_state.dart';

class const LoginButton({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<AuthCubit>();
    final isLoading = cubit.state is AuthLoggingIn;

    return ValueListenableBuilder(
      valueListenable: cubit.usernameController,
      builder: (context, userValue, _) {
        return ValueListenableBuilder(
          valueListenable: cubit.passwordController,
          builder: (_, passwordValue, _) {
            final canSubmit =
                userValue.text.trim().isNotEmpty &&
                passwordValue.text.isNotEmpty &&
                !isLoading;
            return SizedBox(
              width: double.infinity,
              child: AdaptiveButton.filled(
                onPressed: cubit.login,
                enabled: canSubmit,
                child: isLoading
                    ? const AdaptiveLoadingIndicator()
                    : Text('Войти'),
              ),
            );
          },
        );
      },
    );
  }
}
