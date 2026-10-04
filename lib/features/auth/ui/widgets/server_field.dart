import 'package:convetchat/app/adaptive/adaptive_text_field.dart';
import 'package:convetchat/features/auth/ui/bloc/auth_cubit.dart';
import 'package:convetchat/features/auth/ui/bloc/auth_state.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class const ServerField({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<AuthCubit>();
    final isLoading = cubit.state is AuthServerVerifying;

    return AdaptiveTextField(
      controller: cubit.serverController,
      readOnly: isLoading,
      label: 'Адрес',
      hint: 'convet.xyz',
      prefixText: 'https://',
    );
  }
}
