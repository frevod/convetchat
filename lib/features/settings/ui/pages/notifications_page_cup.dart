import 'package:convetchat/features/settings/ui/cubit/settings_cubit.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class const NotificationsPageCup({super.key}) extends StatefulWidget {
  @override
  State<NotificationsPageCup> createState() => _NotificationsPageCupState();
}

class _NotificationsPageCupState() extends State<NotificationsPageCup> {
  bool _peopleEnabled = true;
  bool _groupsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<SettingsCubit>();
    final state = cubit.state;
    final notificationsEnabled = state.notificationsEnabled;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: const Text('Уведомления')),
      child: SafeArea(
        child: ListView(
          children: [
            CupertinoListSection.insetGrouped(
              header: const Text('Общее'),
              backgroundColor: CupertinoColors.transparent,
              children: [
                CupertinoListTile(
                  leading: const Icon(CupertinoIcons.bell_fill),
                  title: const Text('Получать уведомления'),
                  trailing: CupertinoSwitch(
                    value: notificationsEnabled,
                    onChanged: cubit.toggleNotifications,
                  ),
                ),
              ],
            ),
            CupertinoListSection.insetGrouped(
              header: const Text('Категории'),
              backgroundColor: CupertinoColors.transparent,
              children: [
                CupertinoListTile(
                  leading: const Icon(CupertinoIcons.person_fill),
                  title: const Text('Люди'),
                  trailing: CupertinoSwitch(
                    value: _peopleEnabled,
                    onChanged: (v) => setState(() => _peopleEnabled = v),
                  ),
                  onTap: () => setState(() => _peopleEnabled = !_peopleEnabled),
                ),
                CupertinoListTile(
                  leading: const Icon(CupertinoIcons.person_2_fill),
                  title: const Text('Группы'),
                  trailing: CupertinoSwitch(
                    value: _groupsEnabled,
                    onChanged: (v) => setState(() => _groupsEnabled = v),
                  ),
                  onTap: () => setState(() => _groupsEnabled = !_groupsEnabled),
                ),
              ],
            ),
            CupertinoListSection.insetGrouped(
              header: const Text('Типы'),
              backgroundColor: CupertinoColors.transparent,
              children: [
                CupertinoListTile(
                  leading: const Icon(CupertinoIcons.mail),
                  title: const Text('Приглашения'),
                  subtitle: state.invitesSupported
                      ? null
                      : const Text('Сервер не поддерживает'),
                  trailing: CupertinoSwitch(
                    value: state.invitesEnabled,
                    onChanged: state.invitesSupported
                        ? cubit.toggleInvites
                        : null,
                  ),
                  onTap: state.invitesSupported
                      ? () => cubit.toggleInvites(!state.invitesEnabled)
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
