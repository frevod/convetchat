import 'package:convetchat/app/adaptive/adaptive_buttons.dart';
import 'package:convetchat/app/adaptive/adaptive_loading_indicator.dart';
import 'package:convetchat/app/adaptive/adaptive_text_field.dart';
import 'package:convetchat/features/encryption/ui/cubit/encryption_cubit.dart';
import 'package:convetchat/features/encryption/ui/widgets/passphrase_check.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class const NewPassphraseViewCup({super.key}) extends StatelessWidget {
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
        AdaptiveTextField(
          enabled: !state.isLoading,
          readOnly: state.isLoading,
          obscureText: true,
          controller: cubit.newPassphraseController,
          label: 'Новая кодовая фраза',
        ),
        const SizedBox(height: 16),
        AdaptiveTextField(
          enabled: !state.isLoading,
          readOnly: state.isLoading,
          obscureText: true,
          controller: cubit.repeatPassphraseController,
          label: 'Повторите фразу',
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: AdaptiveButton.filled(
            enabled: canCreate,
            onPressed: () =>
                cubit.setOrSkipPassphrase(cubit.newPassphraseController.text),
            child: state.isLoading
                ? const AdaptiveLoadingIndicator()
                : const Text('Продолжить'),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: AdaptiveButton.outlined(
            enabled: !state.isLoading,
            onPressed: () => cubit.setOrSkipPassphrase(null),
            child: Text(
              'Пропустить',
              textAlign: .center,
              style: TextStyle(
                color: CupertinoColors.systemRed.resolveFrom(context),
              ),
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
