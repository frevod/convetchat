import 'package:convetchat/app/adaptive/adaptive_dialog.dart';
import 'package:convetchat/app/adaptive/adaptive_snackbar.dart';
import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/security/app_lock_service.dart';
import 'package:convetchat/features/encryption/domain/repositories/encryption_repository.dart';
import 'package:convetchat/features/settings/domain/repositories/security_repository.dart';
import 'package:convetchat/features/settings/ui/share_keys_with_labels.dart';
import 'package:convetchat/features/settings/ui/widgets/app_lock_pin_sheet.dart';
import 'package:convetchat/features/settings/ui/widgets/settings_section_header.dart';
import 'package:go_router/go_router.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:matrix/matrix.dart';
import 'package:talker_flutter/talker_flutter.dart';

class const SecurityPageAndr({super.key}) extends StatefulWidget {
  @override
  State<SecurityPageAndr> createState() => _SecurityPageAndrState();
}

class _SecurityPageAndrState() extends State<SecurityPageAndr> {
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

  Future<void> _setAppLock(bool value) async {
    if (value) {
      final hasPin = await _security.hasPin();
      if (!mounted) return;
      if (!hasPin) {
        final created = await AppLockPinSheet.showSetup(context);
        if (!mounted) return;
        if (!created) return;
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

  Future<void> _onShareModeChanged(
    List<M3EDropdownItem<ShareKeysWith>> selected,
  ) async {
    if (selected.isEmpty) return;
    final mode = selected.first.value;
    setState(() => _shareMode = mode);
    await _security.setShareKeysMode(mode);
  }

  @override
  Widget build(BuildContext context) {
    final backupReady = _backupReady;
    final lockItems = [
      M3EListItem(
        trailing: _lockLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : M3ESwitch(value: _appLockEnabled, onChanged: _setAppLock),
        leading: const Icon(Icons.lock_rounded),
        headline: 'Блокировка приложения',
        supportingText: _appLockEnabled ? 'Код-пароль включён' : null,
        onTap: _lockLoading ? null : () => _setAppLock(!_appLockEnabled),
      ),
      if (_appLockEnabled)
        M3EListItem(
          leading: const Icon(Icons.pin_rounded),
          headline: 'Изменить код-пароль',
          onTap: _onChangePin,
        ),
      if (_appLockEnabled && _biometricsAvailable)
        M3EListItem(
          trailing: M3ESwitch(
            value: _biometricsEnabled,
            onChanged: _setBiometrics,
          ),
          leading: const Icon(Icons.fingerprint_rounded),
          headline: 'Использовать биометрию',
          onTap: () => _setBiometrics(!_biometricsEnabled),
        ),
    ];
    final shareMode = _shareMode;
    final shareRows = [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              spacing: 16,
              children: [
                const Icon(Icons.key_rounded),
                Text(
                  'Делиться ключами',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Каким устройствам можно доверять чтение ваших сообщений '
              'в зашифрованных чатах?',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            if (shareMode == null)
              const Center(child: CircularProgressIndicator(strokeWidth: 2))
            else
              M3EDropdownMenu<ShareKeysWith>(
                singleSelect: true,
                showChipAnimation: false,
                items: [
                  for (final mode in ShareKeysWith.values)
                    M3EDropdownItem(
                      label: mode.label,
                      value: mode,
                      selected: shareMode == mode,
                    ),
                ],
                onSelectionChanged: _onShareModeChanged,
              ),
          ],
        ),
      ),
    ];
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
          const SettingsSectionHeader(title: 'Резервная копия'),
          M3EList(
            itemCount: 1,
            onTap: (_) {
              if (backupReady != null) _onBackupToggle(!backupReady);
            },
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
                onTap: backupReady == null
                    ? null
                    : () => _onBackupToggle(!backupReady),
              );
            },
          ),
          const SizedBox(height: 12),
          const SettingsSectionHeader(title: 'Блокировка'),
          M3EList(
            itemCount: lockItems.length,
            onTap: (index) => lockItems[index].onTap?.call(),
            itemBuilder: (context, index) => lockItems[index],
          ),
          const SizedBox(height: 12),

          M3EList(
            itemCount: shareRows.length,
            itemBuilder: (context, index) => shareRows[index],
          ),
        ],
      ),
    );
  }
}
