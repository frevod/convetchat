import 'package:convetchat/features/settings/ui/cubit/settings_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

class const ExperimentalPageAndr({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<SettingsCubit>();
    final dehydratedEnabled =
        cubit.state.dehydratedDevicesEnabled ?? true;

    return Scaffold(
      appBar: M3EAppBar.top(
        shapeFamily: .round,
        density: .compact,
        title: const Text('Экспериментальные'),
        automaticallyImplyLeading: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(8.0),
        children: [
          M3EList(
            itemCount: 1,
            onTap: (index) {
              if (index == 0) {
                cubit.setDehydratedDevicesEnabled(!dehydratedEnabled);
              }
            },
            itemBuilder: (context, index) {
              return M3EListItem(
                trailing: M3ESwitch(
                  value: dehydratedEnabled,
                  onChanged: cubit.setDehydratedDevicesEnabled,
                ),
                leading: const Icon(Icons.cloud_sync_rounded),
                headline: 'Dehydrated-устройство',
                supportingText:
                    'Приём ключей шифрования, пока все устройства офлайн. Требует поддержки MSC3814 на сервере',
              );
            },
          ),
        ],
      ),
    );
  }
}
