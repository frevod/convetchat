import 'package:convetchat/app/adaptive/adaptive_buttons.dart';
import 'package:convetchat/app/adaptive/adaptive_dialog.dart';
import 'package:convetchat/app/adaptive/adaptive_loading_indicator.dart';
import 'package:convetchat/core/utils/message_format.dart';
import 'package:convetchat/core/widgets/mxc_avatar.dart';
import 'package:convetchat/features/settings/ui/cubit/settings_cubit.dart';
import 'package:convetchat/features/settings/ui/widgets/launch_account_uri.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

class const SettingsPageAndr({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<SettingsCubit>();
    final state = cubit.state;
    final displayName = state.displayName ?? '';
    final initial = avatarInitial(displayName);
    final userId = state.userId ?? '';

    final List<M3EListItem> group1 = [
      M3EListItem(
        headline: 'Профиль',
        leading: const Icon(Icons.person_rounded),
        onTap: () => context.push('/settings/profile', extra: cubit),
      ),
      M3EListItem(
        headline: 'Аккаунт',
        leading: const Icon(Icons.manage_accounts_rounded),
        trailing: const Icon(Icons.open_in_new_rounded),
        onTap: openAccountManagement,
      ),
      M3EListItem(
        headline: 'Безопасность',
        leading: const Icon(Icons.shield_rounded),
        onTap: () => context.push('/settings/security'),
      ),
    ];

    final List<M3EListItem> group2 = [
      M3EListItem(
        headline: 'Внешний вид',
        leading: const Icon(Icons.palette_rounded),
        onTap: () => context.push('/settings/appearance'),
      ),
      M3EListItem(
        headline: 'Чат',
        leading: const Icon(Icons.message_rounded),
        onTap: () => context.push('/settings/chat'),
      ),
      M3EListItem(
        headline: 'Уведомления',
        leading: const Icon(Icons.notifications_rounded),
        onTap: () => context.push('/settings/notifications'),
      ),
    ];

    final List<M3EListItem> group3 = [
      M3EListItem(
        headline: 'Аналитика',
        supportingText: 'Делиться статистикой использования и сбоями',
        leading: const Icon(Icons.query_stats_rounded),
        trailing: M3ESwitch(
          value: state.telemetryConsent,
          onChanged: cubit.setTelemetryConsent,
        ),
        onTap: () => cubit.setTelemetryConsent(!state.telemetryConsent),
      ),
    ];

    final List<M3EListItem> group4 = [
      M3EListItem(
        headline: 'Сообщить об ошибке',
        leading: const Icon(Icons.bug_report_rounded),
        onTap: () => context.push('/settings/feedback'),
      ),
      M3EListItem(
        headline: 'Логи',
        leading: const Icon(Icons.terminal_rounded),
        onTap: () => context.push('/talker-logs'),
      ),
      M3EListItem(
        headline: 'Экспериментальные',
        leading: const Icon(Icons.science_rounded),
        onTap: () => context.push('/settings/experimental'),
      ),
    ];

    return Scaffold(
      appBar: M3EAppBar.top(
        shapeFamily: .round,
        density: .compact,
        title: const Text('Настройки'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(8.0),
        children: [
          Center(
            child: Column(
              children: [
                MxcAvatar(
                  mxc: state.avatarMxc,
                  fallback: initial,
                  size: 120,
                  showLoadingRing: true,
                  context: context,
                ),
                const SizedBox(height: 8),
                Text(
                  displayName.isNotEmpty ? displayName : userId,
                  style: const TextStyle(fontSize: 30),
                ),
                M3EButton.text(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: userId));
                    HapticFeedback.lightImpact();
                  },
                  onLongPress: () {
                    Clipboard.setData(ClipboardData(text: userId));
                    HapticFeedback.lightImpact();
                  },
                  child: Text(userId, style: const TextStyle(fontSize: 15)),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          M3EList(
            itemCount: group1.length,
            onTap: (index) => group1[index].onTap?.call(),
            itemBuilder: (context, index) => group1[index],
          ),
          const SizedBox(height: 12),
          M3EList(
            itemCount: group2.length,
            onTap: (index) => group2[index].onTap?.call(),
            itemBuilder: (context, index) => group2[index],
          ),
          const SizedBox(height: 12),
          M3EList(
            itemCount: group3.length,
            onTap: (index) => group3[index].onTap?.call(),
            itemBuilder: (context, index) => group3[index],
          ),
          const SizedBox(height: 12),
          M3EList(
            itemCount: group4.length,
            onTap: (index) => group4[index].onTap?.call(),
            itemBuilder: (context, index) => group4[index],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 8.0,
              vertical: 16.0,
            ),
            child: M3EDivider(),
          ),
          AdaptiveButton.filled(
            onPressed: () => _onLogout(context),
            enabled: !state.isLoggingOut,
            isDestructive: true,
            child: state.isLoggingOut
                ? AdaptiveLoadingIndicator()
                : const Text('Выйти'),
          ),
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
