import 'package:convetchat/app/adaptive/adaptive_buttons.dart';
import 'package:convetchat/app/adaptive/adaptive_loading_indicator.dart';
import 'package:convetchat/features/encryption/ui/cubit/encryption_cubit.dart';
import 'package:convetchat/features/encryption/ui/widgets/reset_account_button.dart';
import 'package:convetchat/features/encryption/ui/widgets/restore_devices_list.dart';
import 'package:convetchat/features/encryption/ui/widgets/restore_key_input.dart';
import 'package:convetchat/features/encryption/ui/widgets/verification/verification_sheet.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

class const RestoreBootstrapViewCup({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<EncryptionCubit>();
    final state = cubit.state;

    if (state.verificationState == .askSas) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        final navigator = Navigator.of(context, rootNavigator: false);
        if (!navigator.canPop()) {
          VerificationSheet.show(context, cubit.verification!);
        }
      });
    }

    final hasVerification = state.verificationState != null;

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        if (hasVerification) ...[
          Row(
            crossAxisAlignment: .start,
            children: [
              (state.verificationState == .error ||
                      state.noSecretsReceived ||
                      state.verificationState == .waitingAccept ||
                      state.verificationState == .askChoice)
                  ? CupertinoButton(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(40, 40),
                      onPressed: state.isLoading
                          ? null
                          : cubit.retryVerification,
                      child: const Icon(CupertinoIcons.refresh, size: 22),
                    )
                  : const Padding(
                      padding: EdgeInsets.all(10.0),
                      child: AdaptiveLoadingIndicator(),
                    ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  state.waitingForSecrets
                      ? 'Ожидание ключей…'
                      : state.noSecretsReceived
                      ? 'Ключи не получены'
                      : (state.verificationState == .waitingAccept ||
                            state.verificationState == .askChoice)
                      ? 'Примите запрос на втором устройстве. '
                            'Если ничего не происходит — нажмите ↻.'
                      : 'Подтвердите вход с другого устройства — сравните эмодзи.',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          RestoreDevicesList(
            devices: state.connectedDevices,
            scrollController: cubit.devicesScrollController,
          ),
          Row(
            children: [
              Expanded(child: Divider()),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('или'),
              ),
              const Expanded(child: Divider()),
            ],
          ),
        ] else ...[
          Text(
            'Нет других устройств для подтверждения. Введите кодовую фразу или ключ восстановления.',
            textAlign: .center,
          ),
          const SizedBox(height: 32),
        ],
        if (state.secretsMismatch) ...[
          Text(
            'Ключ подошёл, но секреты шифрования не сошлись: резервная '
            'копия повреждена или пуста. Старые сообщения могут не '
            'расшифроваться. Можно продолжить без них или сбросить '
            'шифрование кнопкой ниже.',
            style: TextStyle(
              color: CupertinoColors.systemRed.resolveFrom(context),
            ),
          ),
          const SizedBox(height: 12),
          AdaptiveButton.filled(
            onPressed: () => cubit.skip(),
            enabled: !state.isLoading,
            child: const Text('Продолжить'),
          ),
          const SizedBox(height: 16),
        ],
        RestoreKeyInput(
          controller: cubit.keyController,
          isLoading: state.isLoading,
          obscureText: state.obscureText,
          keyEntered: state.keyEntered,
          unlockError: state.unlockError,
          onToggleObscure: cubit.toggleObscureText,
          onUnlock: cubit.unlock,
          onOpenKeyFile: cubit.openKeyFile,
          onSubmitted: (_) => cubit.unlock(),
        ),
        const SizedBox(height: 16),
        const ResetAccountButton(),
      ],
    );
  }
}
