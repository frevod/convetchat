import 'package:convetchat/app/adaptive/adaptive_loading_indicator.dart';
import 'package:convetchat/features/auth/domain/entities/auth_mode.dart';
import 'package:convetchat/features/auth/ui/bloc/auth_cubit.dart';
import 'package:convetchat/features/auth/ui/bloc/auth_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_3_expressive/components/buttons/m3e_buttons.dart';
import 'package:material_ui/material_ui.dart';

class const ServerContinueButtonAndr({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<AuthCubit>();
    final isLoading = cubit.state is AuthServerVerifying;

    return ValueListenableBuilder(
      valueListenable: cubit.serverController,
      builder: (context, value, _) {
        final canSubmit = value.text.trim().isNotEmpty && !isLoading;
        return SizedBox(
          width: double.infinity,
          child: M3EButton.filled(
            onPressed: canSubmit ? cubit.verifyServer : null,
            size: .md,
            child: isLoading
                ? const AdaptiveLoadingIndicator()
                : Text(
                    cubit.mode == AuthMode.register
                        ? 'Зарегистрироваться'
                        : 'Войти',
                  ),
          ),
        );
      },
    );
  }
}
