import 'package:convetchat/app/adaptive/adaptive_dialog.dart';
import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/features/encryption/domain/repositories/encryption_repository.dart';
import 'package:go_router/go_router.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:talker_flutter/talker_flutter.dart';

class const SecurityPageAndr({super.key}) extends StatefulWidget {
  @override
  State<SecurityPageAndr> createState() => _SecurityPageAndrState();
}

class _SecurityPageAndrState() extends State<SecurityPageAndr> {
  bool? _backupReady;

  @override
  void initState() {
    super.initState();
    _checkBackup();
  }

  Future<void> _checkBackup() async {
    try {
      final identity = await getIt<EncryptionRepository>().getIdentityState();
      if (!mounted) return;
      setState(() {
        _backupReady = identity.initialized && identity.connected;
      });
    } catch (e, s) {
      getIt<Talker>().error('Не удалось проверить состояние крипты', e, s);
    }
  }

  Future<void> _onBackupToggle(bool value) async {
    if (value) {
      context.go('/backup');
    } else {
      final confirmed = await AdaptiveDialog.confirm(
        context: context,
        title: 'Сбросить резервную копию?',
        message:
            'Ключи шифрования будут пересозданы. '
            'Старые сообщения могут стать недоступны.',
        confirmLabel: 'Сбросить',
        cancelLabel: 'Отмена',
        isDestructive: true,
      );
      if (!confirmed || !mounted) return;
      context.go('/backup?reset=true');
    }
  }

  @override
  Widget build(BuildContext context) {
    final backupReady = _backupReady;
    return Scaffold(
      appBar: M3EAppBar.top(
        shapeFamily: .round,
        density: .compact,
        title: const Text('Безопасность'),
        automaticallyImplyLeading: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(8.0),
        children: [
          M3EList(
            itemCount: 1,
            itemBuilder: (context, index) {
              return M3EListItem(
                trailing: M3ESwitch(
                  value: backupReady == true,
                  onChanged: backupReady == null ? null : _onBackupToggle,
                ),
                leading: const Icon(Icons.backup_rounded),
                headline: 'Резервное копирование чатов',
                supportingText: backupReady == null
                    ? 'Проверка…'
                    : backupReady
                    ? 'Включено'
                    : 'Выключено',
              );
            },
          ),
        ],
      ),
    );
  }
}
