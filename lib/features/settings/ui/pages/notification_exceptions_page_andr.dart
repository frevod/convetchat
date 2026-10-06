import 'package:convetchat/core/widgets/mxc_avatar.dart';
import 'package:convetchat/features/settings/ui/cubit/settings_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

class const NotificationExceptionsPageAndr(
  {super.key, required final bool people})
    extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<SettingsCubit>();
    final exceptions = cubit.categoryExceptions(people);
    return Scaffold(
      appBar: M3EAppBar.top(
        shapeFamily: .round,
        density: .compact,
        title: Text(people ? 'Исключения — Люди' : 'Исключения — Группы'),
        automaticallyImplyLeading: true,
      ),
      body: exceptions.isEmpty
          ? const Center(child: Text('Исключений нет'))
          : ListView(
              padding: const EdgeInsets.all(8.0),
              children: [
                M3EList(
                  itemCount: exceptions.length,
                  itemBuilder: (context, index) {
                    final room = exceptions[index];
                    return M3EListItem(
                      leading: MxcAvatar(
                        context: context,
                        mxc: room.avatarMxc,
                        fallback: room.displayName,
                        size: 40,
                      ),
                      headline: room.displayName,
                      supportingText: room.isMuted
                          ? 'Уведомления отключены'
                          : 'Уведомления включены',
                      swipe: M3EListItemSwipe(
                        mode: .both,
                        edge: .end,
                        trailing: [
                          M3EListSwipeAction(
                            icon: const Icon(Icons.delete_outline_rounded),
                            onPressed: () =>
                                cubit.removeException(room, people),
                          ),
                        ],
                        onDismiss: (direction) async {
                          await cubit.removeException(room, people);
                          return false;
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
    );
  }
}
