import 'package:convetchat/features/settings/ui/cubit/settings_cubit.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class const NotificationsPageCup({super.key}) extends StatelessWidget {
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
          ],
        ),
      ),
    );
  }
}
