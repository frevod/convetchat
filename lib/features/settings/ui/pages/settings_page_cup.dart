import 'dart:async';

import 'package:convetchat/app/adaptive/adaptive_buttons.dart';
import 'package:convetchat/app/adaptive/adaptive_dialog.dart';
import 'package:convetchat/app/adaptive/adaptive_loading_indicator.dart';
import 'package:convetchat/core/utils/message_format.dart';
import 'package:convetchat/core/widgets/mxc_avatar.dart';
import 'package:convetchat/features/settings/ui/cubit/settings_cubit.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:convetchat/features/settings/ui/widgets/launch_account_uri.dart';

class const SettingsPageCup({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<SettingsCubit>();
    final state = cubit.state;
    final displayName = state.displayName ?? '';
    final initial = avatarInitial(displayName);
    final userId = state.userId ?? '';

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: Text('Настройки')),
      child: ListView(
        children: [
          Center(
            child: Column(
              children: [
                MxcAvatar(
                  mxc: state.avatarMxc,
                  fallback: initial,
                  size: 96,
                  showLoadingRing: true,
                  context: context,
                ),
                const SizedBox(height: 12),
                Text(
                  displayName.isNotEmpty ? displayName : userId,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                CupertinoButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: userId));
                    HapticFeedback.lightImpact();
                  },
                  padding: EdgeInsets.zero,
                  child: Text(userId, style: const TextStyle(fontSize: 14)),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          CupertinoListSection.insetGrouped(
            backgroundColor: CupertinoColors.transparent,

            children: [
              CupertinoListTile(
                leading: _SettingsIcon(
                  icon: CupertinoIcons.person_fill,
                  color: CupertinoColors.systemGrey.resolveFrom(context),
                ),
                title: const Text('Профиль'),
                trailing: const CupertinoListTileChevron(),
                onTap: () => context.push('/settings/profile', extra: cubit),
              ),
              CupertinoListTile(
                leading: _SettingsIcon(
                  icon: CupertinoIcons.person_crop_circle_badge_checkmark,
                  color: CupertinoColors.systemIndigo.resolveFrom(context),
                ),
                title: const Text('Аккаунт'),
                subtitle: const Text('Пароль, устройства и ключи на сайте'),
                trailing: const Icon(
                  CupertinoIcons.arrow_up_right_square,
                  size: 20,
                ),
                onTap: () => unawaited(openAccountManagement()),
              ),
              CupertinoListTile(
                leading: _SettingsIcon(
                  icon: CupertinoIcons.shield_fill,
                  color: CupertinoColors.systemBlue.resolveFrom(context),
                ),
                title: const Text('Безопасность'),
                trailing: const CupertinoListTileChevron(),
                onTap: () => context.push('/settings/security'),
              ),
            ],
          ),
          CupertinoListSection.insetGrouped(
            backgroundColor: CupertinoColors.transparent,
            children: [
              CupertinoListTile(
                leading: _SettingsIcon(
                  icon: CupertinoIcons.paintbrush_fill,
                  color: CupertinoColors.systemBlue.resolveFrom(context),
                ),
                title: const Text('Внешний вид'),
                trailing: const CupertinoListTileChevron(),
                onTap: () => context.push('/settings/appearance'),
              ),
              CupertinoListTile(
                leading: _SettingsIcon(
                  icon: CupertinoIcons.chat_bubble_fill,
                  color: CupertinoColors.systemGreen.resolveFrom(context),
                ),
                title: const Text('Чат'),
                trailing: const CupertinoListTileChevron(),
                onTap: () => context.push('/settings/chat'),
              ),
              CupertinoListTile(
                leading: _SettingsIcon(
                  icon: CupertinoIcons.bell_fill,
                  color: CupertinoColors.systemRed.resolveFrom(context),
                ),
                title: const Text('Уведомления'),
                trailing: const CupertinoListTileChevron(),
                onTap: () => context.push('/settings/notifications'),
              ),
              CupertinoListTile(
                leading: _SettingsIcon(
                  icon: CupertinoIcons.archivebox_fill,
                  color: CupertinoColors.systemGrey.resolveFrom(context),
                ),
                title: const Text('Данные и память'),
                trailing: const CupertinoListTileChevron(),
                onTap: () => context.push('/settings/storage'),
              ),
            ],
          ),
          CupertinoListSection.insetGrouped(
            backgroundColor: CupertinoColors.transparent,
            children: [
              CupertinoListTile(
                leading: _SettingsIcon(
                  icon: CupertinoIcons.chart_bar_alt_fill,
                  color: CupertinoColors.systemGrey.resolveFrom(context),
                ),
                title: const Text('Аналитика'),
                trailing: CupertinoSwitch(
                  value: state.telemetryConsent,
                  onChanged: cubit.setTelemetryConsent,
                ),
                onTap: () => cubit.setTelemetryConsent(!state.telemetryConsent),
              ),
            ],
          ),
          CupertinoListSection.insetGrouped(
            backgroundColor: CupertinoColors.transparent,
            children: [
              CupertinoListTile(
                leading: _SettingsIcon(
                  icon: CupertinoIcons.ant_fill,
                  color: CupertinoColors.systemOrange.resolveFrom(context),
                ),
                title: const Text('Сообщить об ошибке'),
                trailing: const CupertinoListTileChevron(),
                onTap: () => context.push('/settings/feedback'),
              ),
              CupertinoListTile(
                leading: _SettingsIcon(
                  icon: CupertinoIcons.chevron_left_slash_chevron_right,
                  color: CupertinoColors.systemGrey.resolveFrom(context),
                ),
                title: const Text('Логи'),
                trailing: const CupertinoListTileChevron(),
                onTap: () => context.push('/talker-logs'),
              ),
              CupertinoListTile(
                leading: _SettingsIcon(
                  icon: CupertinoIcons.hammer_fill,
                  color: CupertinoColors.systemPurple.resolveFrom(context),
                ),
                title: const Text('Экспериментальные'),
                trailing: const CupertinoListTileChevron(),
                onTap: () => context.push('/settings/experimental'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: AdaptiveButton.filled(
              onPressed: state.isLoggingOut ? () {} : () => _onLogout(context),
              isDestructive: true,
              child: state.isLoggingOut
                  ? const AdaptiveLoadingIndicator(color: CupertinoColors.white)
                  : const Text(
                      'Выйти',
                      style: TextStyle(color: CupertinoColors.white),
                    ),
            ),
          ),
          SizedBox(height: MediaQuery.paddingOf(context).bottom + 120),
        ],
      ),
    );
  }

  Future<void> _onLogout(BuildContext context) async {
    final cubit = context.read<SettingsCubit>();
    final confirmed = await AdaptiveDialog.confirm(
      context: context,
      title: 'Выйти из аккаунта?',
      message:
          'Убедитесь, что ключ восстановления сохранён, '
          'иначе доступ к зашифрованным сообщениям будет потерян.',
      confirmLabel: 'Выйти',
      cancelLabel: 'Отмена',
      isDestructive: cubit.state.backupReady == false,
    );
    if (!confirmed || !context.mounted) return;
    await cubit.logout();
  }
}

class const _SettingsIcon({
  required final IconData icon,
  required final Color color,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(color: color, borderRadius: .circular(7)),
      child: Icon(icon, color: CupertinoColors.white, size: 17),
    );
  }
}
