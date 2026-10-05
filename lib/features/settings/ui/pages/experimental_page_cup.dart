import 'package:convetchat/features/settings/ui/cubit/settings_cubit.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class const ExperimentalPageCup({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<SettingsCubit>();
    final dehydratedEnabled =
        cubit.state.dehydratedDevicesEnabled ?? true;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Экспериментальные'),
      ),
      child: SafeArea(
        child: ListView(
          children: [
            CupertinoListSection.insetGrouped(
              backgroundColor: CupertinoColors.transparent,
              children: [
                CupertinoListTile(
                  leading: const Icon(CupertinoIcons.cloud_fill),
                  title: const Text('Dehydrated-устройство'),
                  subtitle: const Text(
                    'Приём ключей, пока устройства офлайн. Нужен MSC3814 на сервере',
                  ),
                  trailing: CupertinoSwitch(
                    value: dehydratedEnabled,
                    onChanged: cubit.setDehydratedDevicesEnabled,
                  ),
                  onTap: () => cubit.setDehydratedDevicesEnabled(
                    !dehydratedEnabled,
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
