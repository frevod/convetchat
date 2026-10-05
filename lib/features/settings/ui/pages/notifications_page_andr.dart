import 'package:convetchat/features/settings/ui/cubit/settings_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

class const NotificationsPageAndr({super.key}) extends StatefulWidget {
  @override
  State<NotificationsPageAndr> createState() => _NotificationsPageAndrState();
}

class _NotificationsPageAndrState() extends State<NotificationsPageAndr> {
  bool _peopleEnabled = true;
  bool _groupsEnabled = true;
  bool _mentionsEnabled = true;
  bool _reactionsEnabled = true;
  bool _invitesEnabled = true;

  bool _extraEnabled(int index) {
    return switch (index) {
      0 => _mentionsEnabled,
      1 => _reactionsEnabled,
      _ => _invitesEnabled,
    };
  }

  void _setExtraEnabled(int index, bool value) {
    setState(() {
      switch (index) {
        case 0:
          _mentionsEnabled = value;
        case 1:
          _reactionsEnabled = value;
        default:
          _invitesEnabled = value;
      }
    });
  }

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
          const SizedBox(height: 12),
          M3EList(
            itemCount: 2,
            onTap: (index) {
              setState(() {
                if (index == 0) {
                  _peopleEnabled = !_peopleEnabled;
                } else {
                  _groupsEnabled = !_groupsEnabled;
                }
              });
            },
            itemBuilder: (context, index) {
              final enabled = index == 0 ? _peopleEnabled : _groupsEnabled;
              return M3EListItem(
                leading: Icon(
                  index == 0 ? Icons.person_rounded : Icons.group_rounded,
                ),
                headline: index == 0 ? 'Люди' : 'Группы',
                trailing: M3ESwitch(
                  value: enabled,
                  onChanged: (v) => setState(() {
                    if (index == 0) {
                      _peopleEnabled = v;
                    } else {
                      _groupsEnabled = v;
                    }
                  }),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          M3EList(
            itemCount: 3,
            onTap: (index) => _setExtraEnabled(index, !_extraEnabled(index)),
            itemBuilder: (context, index) {
              return M3EListItem(
                leading: Icon(switch (index) {
                  0 => Icons.alternate_email_rounded,
                  1 => Icons.add_reaction_rounded,
                  _ => Icons.person_add_rounded,
                }),
                headline: switch (index) {
                  0 => 'Упоминания',
                  1 => 'Реакции',
                  _ => 'Приглашения',
                },
                trailing: M3ESwitch(
                  value: _extraEnabled(index),
                  onChanged: (v) => _setExtraEnabled(index, v),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
