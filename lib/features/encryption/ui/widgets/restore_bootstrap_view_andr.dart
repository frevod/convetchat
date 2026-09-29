import 'package:convetchat/app/adaptive/adaptive_loading_indicator.dart';
import 'package:convetchat/features/encryption/ui/cubit/encryption_cubit.dart';
import 'package:convetchat/features/encryption/ui/widgets/reset_account_button.dart';
import 'package:convetchat/features/encryption/ui/widgets/restore_devices_list.dart';
import 'package:convetchat/features/encryption/ui/widgets/restore_key_input.dart';
import 'package:convetchat/features/encryption/ui/widgets/verification/adaptive_sas_sheet.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_3_expressive/components/divider/m3e_divider.dart';
import 'package:material_3_expressive/components/icon_buttons/m3e_icon_buttons.dart';
import 'package:material_ui/material_ui.dart';

class const RestoreBootstrapViewAndr({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<EncryptionCubit>();
    final state = cubit.state;

    if (state.verificationState == .askSas) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;

        final navigator = Navigator.of(context, rootNavigator: false);
        if (!navigator.canPop()) {
          AdaptiveSasSheet.show(context, cubit.verification!);
        }
      });
    }

    final hasVerification = state.verificationState != null;

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        if (hasVerification) ...[
          ListTile(
            leading:
                (state.verificationState == .error ||
                    state.noSecretsReceived ||
                    state.verificationState == .waitingAccept ||
                    state.verificationState == .askChoice)
                ? M3EIconButton(
                    onPressed: state.isLoading ? null : cubit.retryVerification,
                    tooltip: 'Попробовать снова',
                    icon: const Icon(Icons.refresh_rounded),
                  )
                : const Padding(
                    padding: EdgeInsets.all(10.0),
                    child: AdaptiveLoadingIndicator(),
                  ),
            minLeadingWidth: 40,
            title: Text(
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
          const SizedBox(height: 16),
          RestoreDevicesList(
            devices: state.connectedDevices,
            scrollController: cubit.devicesScrollController,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Row(
              children: [
                Expanded(child: M3EDivider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('или'),
                ),
                Expanded(child: M3EDivider()),
              ],
            ),
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
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: .centerLeft,
            child: FilledButton(
              onPressed: state.isLoading ? null : cubit.skip,
              child: const Text('Продолжить'),
            ),
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
