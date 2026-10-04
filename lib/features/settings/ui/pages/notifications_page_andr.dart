import 'package:convetchat/features/settings/ui/cubit/settings_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

class const NotificationsPageAndr({super.key}) extends StatelessWidget {
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
        ],
      ),
    );
  }
}
