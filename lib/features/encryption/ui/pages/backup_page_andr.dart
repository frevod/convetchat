import 'package:convetchat/features/encryption/ui/cubit/encryption_cubit.dart';
import 'package:convetchat/features/encryption/ui/widgets/backup_body.dart';
import 'package:convetchat/features/encryption/ui/widgets/backup_title.dart';
import 'package:convetchat/features/encryption/ui/widgets/close_backup_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_3_expressive/components/app_bars/m3e_app_bars.dart';
import 'package:material_3_expressive/components/buttons/m3e_buttons.dart';
import 'package:material_ui/material_ui.dart';

class const BackupPageAndr({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = context.watch<EncryptionCubit>().state;

    return Scaffold(
      appBar: M3EAppBar.top(
        shapeFamily: .round,
        density: .compact,
        automaticallyImplyLeading: false,
        leading: state.recoveryKey != null
            ? null
            : CloseButton(onPressed: () => closeBackupPage(context)),
        title: Text(backupTitle(state)),
        actions: [
          if (state.recoveryKey != null)
            Padding(
              padding: const EdgeInsets.all(8),
              child: M3EButton.filled(
                size: .sm,
                onPressed: () =>
                    context.read<EncryptionCubit>().finishAndGoChats(),
                child: const Text('Продолжить'),
              ),
            ),
        ],
      ),
      body: const BackupBody(),
    );
  }
}
