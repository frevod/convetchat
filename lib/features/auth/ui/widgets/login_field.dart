import 'package:convetchat/app/adaptive/adaptive_text_field.dart';
import 'package:convetchat/features/auth/ui/bloc/auth_cubit.dart';
import 'package:convetchat/features/auth/ui/bloc/auth_state.dart';
import 'package:convetchat/features/auth/ui/widgets/homeserver_suffix.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class const LoginField({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<AuthCubit>();
    final isLoading = cubit.state is AuthLoggingIn;

    return AdaptiveTextField(
      controller: cubit.usernameController,
      readOnly: isLoading,
      label: 'Имя пользователя',
      prefixText: '@',
      suffixText: homeserverSuffix(),
    );
  }
}
