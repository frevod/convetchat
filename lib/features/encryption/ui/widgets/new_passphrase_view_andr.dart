import 'package:convetchat/app/adaptive/adaptive_loading_indicator.dart';
import 'package:convetchat/features/encryption/ui/cubit/encryption_cubit.dart';
import 'package:convetchat/features/encryption/ui/widgets/passphrase_check.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_3_expressive/components/buttons/m3e_buttons.dart';
import 'package:material_3_expressive/components/icon_buttons/m3e_icon_buttons.dart';
import 'package:material_ui/material_ui.dart';

class const NewPassphraseViewAndr({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<EncryptionCubit>();
    final state = cubit.state;
    final canCreate = state.checks.canCreate && !state.isLoading;

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Text(
          'Придумайте кодовую фразу для защиты ключей шифрования. '
          'Она понадобится для входа на новых устройствах.',
          textAlign: .center,
        ),
        const SizedBox(height: 16),
        TextField(
          obscureText: state.obscureText,
          readOnly: state.isLoading,
          controller: cubit.newPassphraseController,
          decoration: InputDecoration(
            hintText: 'Новая кодовая фраза',
            suffixIcon: M3EIconButton(
              icon: Icon(
                state.obscureText
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
              ),
              onPressed: cubit.toggleObscureText,
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          obscureText: state.obscureText,
          readOnly: state.isLoading,
          controller: cubit.repeatPassphraseController,
          decoration: InputDecoration(hintText: 'Повторите фразу'),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: M3EButton.filled(
            size: .md,
            onPressed: canCreate
                ? () => cubit.setOrSkipPassphrase(
                    cubit.newPassphraseController.text,
                  )
                : null,
            child: state.isLoading
                ? const AdaptiveLoadingIndicator()
                : Text('Продолжить'),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: M3EButton.text(
            size: .md,
            onPressed: state.isLoading
                ? null
                : () => cubit.setOrSkipPassphrase(null),
            child: Text(
              'Пропустить',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ),
        const SizedBox(height: 16),
        PassphraseCheck(
          checked: state.checks.equalsRepeat,
          label: 'Фразы совпадают',
        ),
        const SizedBox(height: 16),
        PassphraseCheck(
          checked: state.checks.longEnough,
          label: 'Минимум 12 символов',
        ),
        const SizedBox(height: 16),
        PassphraseCheck(
          checked: state.checks.upperAndLowerCase,
          label: 'Заглавные и строчные буквы',
        ),
        const SizedBox(height: 16),
        PassphraseCheck(
          checked: state.checks.specialCharacters,
          label: 'Спецсимволы',
        ),
        const SizedBox(height: 16),
        PassphraseCheck(checked: state.checks.numbers, label: 'Цифры'),
      ],
    );
  }
}
