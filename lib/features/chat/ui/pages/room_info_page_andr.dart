import 'package:convetchat/app/adaptive/adaptive_buttons.dart';
import 'package:convetchat/app/adaptive/adaptive_dialog.dart';
import 'package:convetchat/app/adaptive/adaptive_loading_indicator.dart';
import 'package:convetchat/core/utils/message_format.dart';
import 'package:convetchat/core/widgets/mxc_avatar.dart';
import 'package:convetchat/features/chat/domain/entities/room_info.dart';
import 'package:convetchat/features/chat/ui/cubit/room_info_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

class const RoomInfoPageAndr({super.key}) extends StatelessWidget {
  Future<void> _confirmLeave(BuildContext context) async {
    final confirmed = await AdaptiveDialog.confirm(
      context: context,
      title: 'Покинуть комнату?',
      message: 'Вы перестанете получать сообщения из этой комнаты.',
      confirmLabel: 'Покинуть',
      isDestructive: true,
    );
    if (confirmed && context.mounted) {
      context.read<RoomInfoCubit>().leave();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<RoomInfoCubit>();
    final state = cubit.state;
    final info = state.info;

    return Scaffold(
      appBar: M3EAppBar.top(
        shapeFamily: .round,
        density: .compact,
        automaticallyImplyLeading: true,
        title: Text('Информация'),
      ),
      body: state.isLoading || info == null
          ? const Center(child: AdaptiveLoadingIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: Column(
                    children: [
                      MxcAvatar(
                        mxc: info.avatarMxc,
                        fallback: avatarInitial(info.name),
                        size: 88,
                        context: context,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        info.name,
                        textAlign: .center,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      if (info.topic.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          info.topic,
                          textAlign: .center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                      const SizedBox(height: 8),
                      _Badges(info: info),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  title: Text(
                    info.roomId,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  subtitle: Text(
                    info.canonicalAlias ?? 'ID комнаты',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.copy_rounded),
                    tooltip: 'Скопировать ID',
                    onPressed: cubit.copyRoomId,
                  ),
                ),
                const Divider(),
                ListTile(
                  title: Text(
                    info.isDirect
                        ? 'Участники'
                        : 'Участники (${info.memberCount})',
                  ),
                ),
                for (final member in info.members)
                  ListTile(
                    leading: MxcAvatar(
                      mxc: member.avatarMxc,
                      fallback: avatarInitial(member.displayName),
                      size: 40,
                      context: context,
                    ),
                    title: Text(
                      member.displayName,
                      maxLines: 1,
                      overflow: .ellipsis,
                    ),
                    subtitle: Text(
                      member.id,
                      maxLines: 1,
                      overflow: .ellipsis,
                    ),
                    trailing: member.invited
                        ? Text(
                            'Приглашён',
                            style: Theme.of(context).textTheme.labelSmall,
                          )
                        : null,
                  ),
                const SizedBox(height: 16),
                if (state.isLeaving)
                  const Center(child: AdaptiveLoadingIndicator())
                else
                  AdaptiveButton.filled(
                    isDestructive: true,
                    onPressed: () => _confirmLeave(context),
                    child: Text('Покинуть комнату'),
                  ),
              ],
            ),
    );
  }
}

class const _Badges({required final RoomInfo info}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: .center,
      spacing: 8,
      children: [
        Chip(
          label: Text(info.isDirect ? 'Личный чат' : 'Группа'),
        ),
        if (info.encrypted) Chip(label: Text('Шифрование')),
      ],
    );
  }
}
