import 'package:convetchat/app/adaptive/adaptive_text_field.dart';
import 'package:convetchat/features/auth/ui/bloc/auth_cubit.dart';
import 'package:convetchat/features/auth/ui/bloc/auth_state.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class const PasswordField({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<AuthCubit>();
    final isLoading = cubit.state is AuthLoggingIn;

    return AdaptiveTextField(
      controller: cubit.passwordController,
      readOnly: isLoading,
      label: 'Пароль',
      obscureText: true,
    );
  }
}
