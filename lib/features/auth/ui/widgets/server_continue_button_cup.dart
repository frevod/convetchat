import 'package:convetchat/app/adaptive/adaptive_buttons.dart';
import 'package:convetchat/app/adaptive/adaptive_loading_indicator.dart';
import 'package:convetchat/features/auth/domain/entities/auth_mode.dart';
import 'package:convetchat/features/auth/ui/bloc/auth_cubit.dart';
import 'package:convetchat/features/auth/ui/bloc/auth_state.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class const ServerContinueButtonCup({super.key}) extends StatelessWidget {
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
          child: AdaptiveButton.filled(
            enabled: canSubmit,
            onPressed: cubit.verifyServer,
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
