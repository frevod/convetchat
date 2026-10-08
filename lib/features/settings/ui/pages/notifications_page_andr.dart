import 'package:convetchat/app/adaptive/adaptive_dialog.dart';
import 'package:convetchat/features/settings/ui/cubit/settings_cubit.dart';
import 'package:convetchat/features/settings/ui/widgets/settings_section_header.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

class const NotificationsPageAndr({super.key}) extends StatefulWidget {
  @override
  State<NotificationsPageAndr> createState() => _NotificationsPageAndrState();
}

class _NotificationsPageAndrState() extends State<NotificationsPageAndr> {
  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<SettingsCubit>();
    final state = cubit.state;
    final notificationsEnabled = state.notificationsEnabled;

    return Scaffold(
      appBar: M3EAppBar.top(
        shapeFamily: .round,
        density: .compact,
        title: const Text('Уведомления'),
        automaticallyImplyLeading: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(8.0),
        children: [
          const SettingsSectionHeader(title: 'Общее'),
          M3EList(
            itemCount: 1,
            onTap: (index) {
              if (index == 0) {
                cubit.toggleNotifications(!notificationsEnabled);
              }
            },
            itemBuilder: (context, index) {
              return M3EListItem(
                trailing: M3ESwitch(
                  value: notificationsEnabled,
                  onChanged: cubit.toggleNotifications,
                ),
                leading: const Icon(Icons.notifications_rounded),
                headline: 'Получать уведомления',
              );
            },
          ),
          const SizedBox(height: 12),
          const SettingsSectionHeader(title: 'Содержимое'),
          M3EList(
            itemCount: 1,
            onTap: (index) {
              cubit.toggleContentPreview(!state.contentPreview);
            },
            itemBuilder: (context, index) {
              return M3EListItem(
                leading: const Icon(Icons.preview_rounded),
                headline: 'Предпросмотр контента',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    M3ESwitch(
                      value: state.contentPreview,
                      onChanged: cubit.toggleContentPreview,
                    ),
                    M3EIconButton(
                      icon: const Icon(Icons.help_outline_rounded),
                      variant: .standard,
                      tooltip: 'Подробнее',
                      onPressed: () => AdaptiveDialog.show(
                        context: context,
                        title: 'Предпросмотр контента',
                        subtitle: 'Когда этот параметр включен, при входящем сообщении ConvetChat пытается локально расшифровать сообщение. Однако расшифровка отправляет в онлайн и это вынужденная мера. Если же выключено или расшифровать не удастся, то уведомление будет содержать просто информацию о том, что у вас новое сообщение',
                        actions: const [
                          AdaptiveDialogAction(
                            label: 'Понятно',
                            isPrimary: true,
                            result: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          const SettingsSectionHeader(title: 'Категории'),
          M3EList(
            itemCount: 2,
            onTap: (index) {
              final people = index == 0;
              context.push(
                '/settings/notifications/exceptions?type=${people ? 'people' : 'groups'}',
                extra: cubit,
              );
            },
            itemBuilder: (context, index) {
              final people = index == 0;
              final enabled = people
                  ? state.peopleEnabled
                  : state.groupsEnabled;
              return M3EListItem(
                leading: Icon(
                  people ? Icons.person_rounded : Icons.group_rounded,
                ),
                headline: people ? 'Люди' : 'Группы',
                supportingText: 'Нажмите для управления исключениями',
                trailing: Row(
                  spacing: 5,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      height: 32,
                      child: VerticalDivider(width: 3),
                    ),

                    M3ESwitch(
                      value: enabled,
                      onChanged: people
                          ? cubit.togglePeopleCategory
                          : cubit.toggleGroupsCategory,
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          M3EList(
            itemCount: 1,
            onTap: (index) {
              if (state.invitesSupported) {
                cubit.toggleInvites(!state.invitesEnabled);
              }
            },
            itemBuilder: (context, index) {
              return M3EListItem(
                enabled: state.invitesSupported,
                leading: const Icon(Icons.person_add_rounded),
                headline: 'Приглашения',
                supportingText: state.invitesSupported
                    ? null
                    : 'Сервер не поддерживает',
                trailing: M3ESwitch(
                  value: state.invitesEnabled,
                  onChanged: state.invitesSupported
                      ? cubit.toggleInvites
                      : null,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
