import 'package:convetchat/app/adaptive/adaptive_buttons.dart';
import 'package:convetchat/app/adaptive/adaptive_dialog.dart';
import 'package:convetchat/app/adaptive/adaptive_loading_indicator.dart';
import 'package:convetchat/core/utils/message_format.dart';
import 'package:convetchat/core/widgets/mxc_avatar.dart';
import 'package:convetchat/features/chat/domain/entities/room_info.dart';
import 'package:convetchat/features/chat/ui/cubit/room_info_cubit.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class const RoomInfoPageCup({super.key}) extends StatelessWidget {
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

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('Информация')),
      child: SafeArea(
        child: state.isLoading || info == null
            ? const Center(child: AdaptiveLoadingIndicator())
            : ListView(
                padding: const EdgeInsets.all(20),
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
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: .w600,
                          ),
                        ),
                        if (info.topic.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            info.topic,
                            textAlign: .center,
                            style: TextStyle(
                              fontSize: 15,
                              color: CupertinoColors.secondaryLabel.resolveFrom(
                                context,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        _Badges(info: info),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  CupertinoListSection.insetGrouped(
                    header: const Text('Комната'),
                    children: [
                      CupertinoListTile(
                        title: Text(
                          info.roomId,
                          style: const TextStyle(fontSize: 13),
                        ),
                        subtitle: info.canonicalAlias != null
                            ? Text(info.canonicalAlias!)
                            : null,
                        trailing: CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: cubit.copyRoomId,
                          child: const Icon(CupertinoIcons.doc_on_doc),
                        ),
                      ),
                    ],
                  ),
                  CupertinoListSection.insetGrouped(
                    header: Text(
                      info.isDirect
                          ? 'Участники'
                          : 'Участники (${info.memberCount})',
                    ),
                    children: [
                      for (final member in info.members)
                        CupertinoListTile(
                          leading: MxcAvatar(
                            mxc: member.avatarMxc,
                            fallback: avatarInitial(member.displayName),
                            size: 36,
                            context: context,
                          ),
                          title: Text(
                            member.displayName,
                            maxLines: 1,
                            overflow: .ellipsis,
                          ),
                          subtitle: Text(
                            member.invited ? 'Приглашён' : member.id,
                            maxLines: 1,
                            overflow: .ellipsis,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (state.isLeaving)
                    const Center(child: AdaptiveLoadingIndicator())
                  else
                    AdaptiveButton.filled(
                      isDestructive: true,
                      onPressed: () => _confirmLeave(context),
                      child: const Text('Покинуть комнату'),
                    ),
                ],
              ),
      ),
    );
  }
}

class const _Badges({required final RoomInfo info}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final labels = <String>[
      info.isDirect ? 'Личный чат' : 'Группа',
      if (info.encrypted) 'Шифрование',
    ];
    return Wrap(
      alignment: .center,
      spacing: 8,
      children: [
        for (final label in labels)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: CupertinoColors.systemFill.resolveFrom(context),
              borderRadius: .circular(12),
            ),
            child: Text(label, style: const TextStyle(fontSize: 13)),
          ),
      ],
    );
  }
}
