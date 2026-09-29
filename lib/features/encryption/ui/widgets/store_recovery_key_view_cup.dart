import 'package:convetchat/app/adaptive/adaptive_buttons.dart';
import 'package:convetchat/app/adaptive/adaptive_text_field.dart';
import 'package:convetchat/core/utils/share_text.dart';
import 'package:convetchat/features/encryption/ui/cubit/encryption_cubit.dart';
import 'package:convetchat/features/encryption/ui/widgets/secure_storage_name.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class const StoreRecoveryKeyViewCup({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<EncryptionCubit>();
    final state = cubit.state;

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Text(
          'Сохраните ключ восстановления в надёжном месте. '
          'Он понадобится для входа на новых устройствах.',
        ),
        const SizedBox(height: 16),
        AdaptiveTextField(
          controller: TextEditingController(text: state.recoveryKey),
          enabled: false,
          readOnly: true,
          maxLines: 4,
        ),
        const SizedBox(height: 16),
        Center(
          child: AdaptiveButton.filled(
            onPressed: () => shareText(state.recoveryKey ?? '', context),
            child: const Row(
              mainAxisSize: .min,
              children: [
                Icon(CupertinoIcons.doc_on_clipboard, size: 20),
                SizedBox(width: 8),
                Text('Копировать'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _KeyCheck(
          value: state.keyDownloaded,
          onChanged: cubit.toggleKeyDownloaded,
          title: 'Сохранить в файл',
        ),
        if (cubit.supportsSecureStorage)
          _KeyCheck(
            value: state.keyInSecureStorage,
            onChanged: cubit.toggleKeyInSecureStorage,
            title: secureStorageName(),
          ),
      ],
    );
  }
}

class const _KeyCheck({
  required final bool value,
  required final ValueChanged<bool?> onChanged,
  required final String title,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      behavior: .opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Icon(
              value
                  ? CupertinoIcons.check_mark_circled_solid
                  : CupertinoIcons.circle,
              color: value
                  ? CupertinoColors.activeBlue.resolveFrom(context)
                  : CupertinoColors.systemGrey.resolveFrom(context),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(title)),
          ],
        ),
      ),
    );
  }
}
