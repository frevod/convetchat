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
  bool _mentionsEnabled = true;
  bool _reactionsEnabled = true;
  bool _invitesEnabled = true;

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
              backgroundColor: CupertinoColors.transparent,
              children: [
                CupertinoListTile(
                  leading: const Icon(CupertinoIcons.person_fill),
                  title: const Text('Люди'),
                  trailing: CupertinoSwitch(
                    value: _peopleEnabled,
                    onChanged: (v) => setState(() => _peopleEnabled = v),
                  ),
                  onTap: () =>
                      setState(() => _peopleEnabled = !_peopleEnabled),
                ),
                CupertinoListTile(
                  leading: const Icon(CupertinoIcons.person_2_fill),
                  title: const Text('Группы'),
                  trailing: CupertinoSwitch(
                    value: _groupsEnabled,
                    onChanged: (v) => setState(() => _groupsEnabled = v),
                  ),
                  onTap: () =>
                      setState(() => _groupsEnabled = !_groupsEnabled),
                ),
              ],
            ),
            CupertinoListSection.insetGrouped(
              backgroundColor: CupertinoColors.transparent,
              children: [
                CupertinoListTile(
                  leading: const Icon(CupertinoIcons.at),
                  title: const Text('Упоминания'),
                  trailing: CupertinoSwitch(
                    value: _mentionsEnabled,
                    onChanged: (v) => setState(() => _mentionsEnabled = v),
                  ),
                  onTap: () =>
                      setState(() => _mentionsEnabled = !_mentionsEnabled),
                ),
                CupertinoListTile(
                  leading: const Icon(CupertinoIcons.smiley),
                  title: const Text('Реакции'),
                  trailing: CupertinoSwitch(
                    value: _reactionsEnabled,
                    onChanged: (v) => setState(() => _reactionsEnabled = v),
                  ),
                  onTap: () =>
                      setState(() => _reactionsEnabled = !_reactionsEnabled),
                ),
                CupertinoListTile(
                  leading: const Icon(CupertinoIcons.mail),
                  title: const Text('Приглашения'),
                  trailing: CupertinoSwitch(
                    value: _invitesEnabled,
                    onChanged: (v) => setState(() => _invitesEnabled = v),
                  ),
                  onTap: () =>
                      setState(() => _invitesEnabled = !_invitesEnabled),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
