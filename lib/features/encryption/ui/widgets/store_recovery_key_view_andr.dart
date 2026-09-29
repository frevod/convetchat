import 'package:convetchat/core/utils/share_text.dart';
import 'package:convetchat/features/encryption/ui/cubit/encryption_cubit.dart';
import 'package:convetchat/features/encryption/ui/widgets/secure_storage_name.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_3_expressive/components/checkbox/m3e_checkbox.dart';
import 'package:material_3_expressive/components/icon_buttons/m3e_icon_buttons.dart';
import 'package:material_ui/material_ui.dart';

class const StoreRecoveryKeyViewAndr({super.key}) extends StatelessWidget {
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
        TextField(
          controller: TextEditingController(text: state.recoveryKey),
          readOnly: true,
          minLines: 2,
          maxLines: 4,
          decoration: InputDecoration(
            suffixIcon: M3EIconButton(
              icon: const Icon(Icons.copy_rounded),
              onPressed: () => shareText(state.recoveryKey ?? '', context),
            ),
          ),
        ),
        const SizedBox(height: 16),
        M3ECheckbox(
          value: state.keyDownloaded,
          onChanged: cubit.toggleKeyDownloaded,
          label: const Text('Сохранить в файл'),
        ),
        if (cubit.supportsSecureStorage)
          M3ECheckbox(
            value: state.keyInSecureStorage,
            onChanged: cubit.toggleKeyInSecureStorage,
            label: Text(secureStorageName()),
          ),
      ],
    );
  }
}
