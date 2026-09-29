import 'package:convetchat/features/encryption/ui/cubit/encryption_cubit.dart';
import 'package:convetchat/features/encryption/ui/widgets/backup_body.dart';
import 'package:convetchat/features/encryption/ui/widgets/backup_title.dart';
import 'package:convetchat/features/encryption/ui/widgets/close_backup_page.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class const BackupPageCup({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<EncryptionCubit>();
    final state = cubit.state;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(backupTitle(state)),
        leading: state.recoveryKey != null
            ? null
            : CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => closeBackupPage(context),
                child: const Icon(CupertinoIcons.xmark),
              ),
        trailing: state.recoveryKey != null
            ? CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: cubit.finishAndGoChats,
                child: const Text('Продолжить'),
              )
            : null,
      ),
      child: SafeArea(child: BackupBody()),
    );
  }
}
