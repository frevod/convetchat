import 'package:convetchat/app/adaptive/adaptive_dialog.dart';
import 'package:convetchat/features/encryption/ui/cubit/encryption_cubit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

Future<void> closeBackupPage(BuildContext context) async {
  final cubit = context.read<EncryptionCubit>();
  if (!cubit.state.reset) {
    final skip = await AdaptiveDialog.confirm(
      context: context,
      title: 'Пропустить резервную копию?',
      message:
          'Без ключа восстановления вы потеряете доступ '
          'к зашифрованным сообщениям на новых устройствах.',
      confirmLabel: 'Пропустить',
      cancelLabel: 'Отмена',
      isDestructive: true,
    );
    if (!skip) return;
  }
  await cubit.skip();
}
