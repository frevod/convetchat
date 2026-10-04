import 'package:convetchat/app/adaptive/adaptive_snackbar.dart';
import 'package:convetchat/features/auth/ui/bloc/auth_cubit.dart';
import 'package:convetchat/features/auth/ui/bloc/auth_state.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class const AuthFailureListener({super.key, required final Widget child})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthFailure) {
          AdaptiveSnackbar.show(
            context: context,
            message: state.message,
            type: .error,
          );
          context.read<AuthCubit>().clearError();
        }
      },
      child: child,
    );
  }
}
