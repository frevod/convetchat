import 'package:convetchat/app/adaptive/adaptive_buttons.dart';
import 'package:convetchat/app/adaptive/adaptive_dialog.dart';
import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/platform_style.dart';
import 'package:convetchat/features/encryption/ui/cubit/encryption_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_3_expressive/components/buttons/m3e_buttons.dart';
import 'package:material_ui/material_ui.dart';

class const ResetAccountButton({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (getIt<PlatformStyle>().isCupertino) {
      return SizedBox(
        width: double.infinity,
        child: AdaptiveButton.filled(
          isDestructive: true,
          onPressed: () => _onTap(context),
          child: const Text('Сбросить аккаунт'),
        ),
      );
    }
    final danger = Theme.of(context).colorScheme.error;
    return M3EButton.text(
      size: .md,
      onPressed: () => _onTap(context),
      child: Text('Сбросить аккаунт', style: TextStyle(color: danger)),
    );
  }

  Future<void> _onTap(BuildContext context) async {
    final confirmed = await AdaptiveDialog.confirm(
      context: context,
      title: 'Внимание',
      message:
          'Сброс обнулит ключи шифрования. Старые сообщения '
          'могут стать недоступны.',
      confirmLabel: 'Сбросить аккаунт',
      cancelLabel: 'Отмена',
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) return;
    context.read<EncryptionCubit>().startReset();
  }
}
