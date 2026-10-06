import 'dart:async';

import 'package:convetchat/app/adaptive/adaptive_snackbar.dart';
import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/security/app_lock_service.dart';
import 'package:convetchat/features/encryption/domain/repositories/encryption_repository.dart';
import 'package:convetchat/features/settings/domain/repositories/security_repository.dart';
import 'package:convetchat/features/settings/ui/share_keys_with_labels.dart';
import 'package:convetchat/features/settings/ui/widgets/app_lock_pin_sheet.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:matrix/matrix.dart';
import 'package:talker_flutter/talker_flutter.dart';

class const SecurityPageCup({super.key}) extends StatefulWidget {
  @override
  State<SecurityPageCup> createState() => _SecurityPageCupState();
}

class _SecurityPageCupState() extends State<SecurityPageCup> {
  bool? _backupReady;
  bool _appLockEnabled = false;
  bool _biometricsEnabled = false;
  bool _biometricsAvailable = false;
  bool _lockLoading = true;
  ShareKeysWith? _shareMode;

  SecurityRepository get _security => getIt<SecurityRepository>();

  @override
  void initState() {
    super.initState();
    _checkBackup();
    _loadLock();
    _loadShareMode();
  }

  Future<void> _checkBackup() async {
    try {
      final identity = await getIt<EncryptionRepository>().getIdentityState();
      if (!mounted) return;
      setState(() {
        _backupReady = identity.initialized && identity.connected;
      });
    } catch (e, s) {
      getIt<Talker>().error('[security] check backup state failed', e, s);
    }
  }

  Future<void> _loadLock() async {
    try {
      final enabled = await _security.isAppLockEnabled();
      final biometric = await _security.isBiometricsEnabled();
      final available = await _security.canCheckBiometrics();
      if (!mounted) return;
      setState(() {
        _appLockEnabled = enabled;
        _biometricsEnabled = biometric && enabled;
        _biometricsAvailable = available;
        _lockLoading = false;
      });
    } catch (e, s) {
      getIt<Talker>().error('[security] read app lock failed', e, s);
      if (!mounted) return;
      setState(() => _lockLoading = false);
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

  Future<void> _setAppLock(bool value) async {
    if (value) {
      final hasPin = await _security.hasPin();
      if (!mounted) return;
      if (!hasPin) {
        final created = await AppLockPinSheet.showSetup(context);
        if (!mounted || !created) return;
      } else {
        await _security.setAppLockEnabled(true);
      }
      setState(() => _appLockEnabled = true);
      await getIt<AppLockService>().refresh();
      return;
    }
    final ok = await _confirmOwnership();
    if (!ok || !mounted) return;
    await _security.setAppLockEnabled(false);
    await _security.clearPin();
    await getIt<AppLockService>().refresh();
    if (!mounted) return;
    setState(() {
      _appLockEnabled = false;
      _biometricsEnabled = false;
    });
    AdaptiveSnackbar.show(
      context: context,
      message: 'Блокировка выключена, код удалён',
      type: .info,
    );
  }

  Future<bool> _confirmOwnership() async {
    if (_biometricsEnabled && _biometricsAvailable) {
      final ok = await _security.authenticate(
        reason: 'Подтвердите, чтобы изменить блокировку',
      );
      if (ok) return true;
      if (!mounted) return false;
    }
    if (!mounted) return false;
    return AppLockPinSheet.showVerify(context);
  }

  Future<void> _setBiometrics(bool value) async {
    if (value) {
      final available = await _security.canCheckBiometrics();
      if (!mounted) return;
      if (!available) {
        AdaptiveSnackbar.show(
          context: context,
          message: 'Биометрия недоступна на этом устройстве',
          type: .warning,
        );
        return;
      }
      final ok = await _security.authenticate(
        reason: 'Включите вход по биометрии',
      );
      if (!mounted) return;
      if (!ok) {
        AdaptiveSnackbar.show(
          context: context,
          message: 'Не удалось подтвердить биометрию',
          type: .error,
        );
        return;
      }
      await _security.setBiometricsEnabled(true);
      if (!mounted) return;
      setState(() => _biometricsEnabled = true);
      return;
    }
    await _security.setBiometricsEnabled(false);
    if (!mounted) return;
    setState(() => _biometricsEnabled = false);
  }

  Future<void> _onChangePin() async {
    final changed = await AppLockPinSheet.showChange(context);
    if (!mounted || !changed) return;
    AdaptiveSnackbar.show(
      context: context,
      message: 'Код-пароль обновлён',
      type: .success,
    );
  }

  Future<void> _loadShareMode() async {
    try {
      final mode = await _security.getShareKeysMode();
      if (!mounted) return;
      setState(() => _shareMode = mode);
    } catch (e, s) {
      getIt<Talker>().error('[security] read shareKeysWith failed', e, s);
    }
  }

  Future<void> _setShareMode(ShareKeysWith mode) async {
    setState(() => _shareMode = mode);
    await _security.setShareKeysMode(mode);
  }

  CupertinoListTile _shareModeTile(ShareKeysWith mode, IconData icon) {
    final selected = _shareMode == mode;
    return CupertinoListTile(
      leading: Icon(icon),
      title: Text(mode.label),
      subtitle: Text(mode.description),
      trailing: selected ? const Icon(CupertinoIcons.check_mark) : null,
      onTap: () => unawaited(_setShareMode(mode)),
    );
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
                    onTap: () => unawaited(_onBackupToggle(!backupReady)),
                  ),
              ],
            ),
            CupertinoListSection.insetGrouped(
              backgroundColor: CupertinoColors.transparent,
              children: [
                CupertinoListTile(
                  leading: const Icon(CupertinoIcons.lock_fill),
                  title: const Text('Блокировка приложения'),
                  subtitle: _lockLoading
                      ? const Text('Загрузка…')
                      : _appLockEnabled
                          ? const Text('Код-пароль включён')
                          : null,
                  trailing: _lockLoading
                      ? const CupertinoActivityIndicator()
                      : CupertinoSwitch(
                          value: _appLockEnabled,
                          onChanged: _setAppLock,
                        ),
                  onTap: _lockLoading
                      ? null
                      : () => _setAppLock(!_appLockEnabled),
                ),
                if (_appLockEnabled)
                  CupertinoListTile(
                    leading: const Icon(CupertinoIcons.number),
                    title: const Text('Код-пароль'),
                    subtitle: const Text('Изменить код из 4 цифр'),
                    trailing: const Icon(CupertinoIcons.chevron_right),
                    onTap: _onChangePin,
                  ),
                if (_appLockEnabled && _biometricsAvailable)
                  CupertinoListTile(
                    leading: const Icon(CupertinoIcons.viewfinder),
                    title: const Text('Использовать биометрию'),
                    trailing: CupertinoSwitch(
                      value: _biometricsEnabled,
                      onChanged: (v) => unawaited(_setBiometrics(v)),
                    ),
                    onTap: () => unawaited(
                      _setBiometrics(!_biometricsEnabled),
                    ),
                  ),
              ],
            ),
            CupertinoListSection.insetGrouped(
              backgroundColor: CupertinoColors.transparent,
              header: const Text('Делиться ключами'),
              footer: const Text(
                'Каким устройствам можно доверять чтение ваших сообщений '
                'в зашифрованных чатах?',
              ),
              children: [
                if (_shareMode == null)
                  const CupertinoListTile(
                    title: Text('Загрузка…'),
                  )
                else ...[
                  _shareModeTile(
                    ShareKeysWith.all,
                    CupertinoIcons.device_phone_portrait,
                  ),
                  _shareModeTile(
                    ShareKeysWith.crossVerifiedIfEnabled,
                    CupertinoIcons.checkmark_shield_fill,
                  ),
                  _shareModeTile(
                    ShareKeysWith.crossVerified,
                    CupertinoIcons.shield_fill,
                  ),
                  _shareModeTile(
                    ShareKeysWith.directlyVerifiedOnly,
                    CupertinoIcons.lock_shield,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
