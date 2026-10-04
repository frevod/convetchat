import 'dart:async';

import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/features/encryption/domain/repositories/encryption_repository.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:talker_flutter/talker_flutter.dart';

class const SecurityPageCup({super.key}) extends StatefulWidget {
  @override
  State<SecurityPageCup> createState() => _SecurityPageCupState();
}

class _SecurityPageCupState() extends State<SecurityPageCup> {
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
      final confirmed = await showCupertinoDialog<bool>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Сбросить резервную копию?'),
          content: const Text(
            'Ключи шифрования будут пересозданы. '
            'Старые сообщения могут стать недоступны.',
          ),
          actions: [
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Сбросить'),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Отмена'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      context.go('/backup?reset=true');
    }
  }

  @override
  Widget build(BuildContext context) {
    final backupReady = _backupReady;
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: const Text('Безопасность')),
      child: SafeArea(
        child: ListView(
          children: [
            CupertinoListSection.insetGrouped(
              backgroundColor: CupertinoColors.transparent,
              children: [
                if (backupReady == null)
                  const CupertinoListTile(
                    leading: Icon(CupertinoIcons.lock_shield),
                    title: Text('Резервное копирование чатов'),
                    subtitle: Text('Проверка…'),
                  )
                else
                  CupertinoListTile(
                    leading: const Icon(CupertinoIcons.lock_shield),
                    title: const Text('Резервное копирование чатов'),
                    subtitle: Text(backupReady ? 'Включено' : 'Выключено'),
                    trailing: CupertinoSwitch(
                      value: backupReady,
                      onChanged: (bool v) {
                        unawaited(_onBackupToggle(v));
                      },
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
