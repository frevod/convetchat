import 'package:convetchat/app/adaptive/adaptive_dialog.dart';
import 'package:convetchat/core/utils/message_format.dart';
import 'package:convetchat/core/widgets/mxc_avatar.dart';
import 'package:convetchat/features/chats/domain/entities/chat_room.dart';
import 'package:convetchat/features/chats/ui/cubit/chats_cubit.dart';
import 'package:convetchat/features/chats/ui/widgets/message_time_text.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class const RoomItemCup({super.key, required final ChatRoom room})
    extends StatelessWidget {
  Future<void> _showMenu(BuildContext context) async {
    final action = await showCupertinoModalPopup<String>(
      context: context,
      builder: (sheetContext) => CupertinoActionSheet(
        title: Text(room.displayName),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () => Navigator.of(sheetContext).pop('mute'),
            child: Text(
              room.isMuted ? 'Включить уведомления' : 'Отключить уведомления',
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.of(sheetContext).pop('pin'),
            child: Text(room.isPinned ? 'Открепить' : 'Закрепить'),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(sheetContext).pop('leave'),
            child: const Text('Покинуть комнату'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(sheetContext).pop(),
          child: const Text('Отмена'),
        ),
      ),
    );
    if (!context.mounted) return;
    final cubit = context.read<ChatsCubit>();
    switch (action) {
      case 'mute':
        cubit.toggleMute(room);
      case 'pin':
        cubit.togglePin(room);
      case 'leave':
        final confirmed = await AdaptiveDialog.confirm(
          context: context,
          title: 'Покинуть комнату?',
          message:
              'Вы перестанете получать сообщения из «${room.displayName}».',
          confirmLabel: 'Покинуть',
          isDestructive: true,
        );
        if (confirmed && context.mounted) {
          context.read<ChatsCubit>().leaveRoom(room);
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final initial = avatarInitial(room.displayName);
    final isUnread = room.unreadCount > 0;
    final label = CupertinoColors.label.resolveFrom(context);
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    final tertiary = CupertinoColors.tertiaryLabel.resolveFrom(context);
    final dotBlue = CupertinoColors.systemBlue.resolveFrom(context);

    return GestureDetector(
      behavior: .opaque,
      onTap: () => context.push('/chat/${room.id}'),
      onLongPress: () => _showMenu(context),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: 8,
              right: 16,
              top: 10,
              bottom: 12,
            ),
            child: Row(
              crossAxisAlignment: .center,
              children: [
                SizedBox(
                  width: 12,
                  child: isUnread
                      ? Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: dotBlue,
                            shape: .circle,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 4),
                Stack(
                  clipBehavior: .none,
                  children: [
                    MxcAvatar(
                      mxc: room.avatarMxc,
                      fallback: initial,
                      size: 52,
                      context: context,
                    ),
                    if (room.isDirect && (room.online || room.busy))
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 15,
                          height: 15,
                          decoration: BoxDecoration(
                            color: room.busy
                                ? CupertinoColors.systemOrange.resolveFrom(
                                    context,
                                  )
                                : CupertinoColors.systemBlue.resolveFrom(
                                    context,
                                  ),
                            shape: .circle,
                            border: Border.all(
                              color: CupertinoColors.systemBackground
                                  .resolveFrom(context),
                              width: 2.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: .start,
                    children: [
                      Row(
                        children: [
                          if (room.isPinned) ...[
                            Icon(
                              CupertinoIcons.pin_fill,
                              size: 14,
                              color: secondary,
                            ),
                            const SizedBox(width: 4),
                          ],
                          Expanded(
                            child: Text(
                              room.displayName,
                              style: TextStyle(
                                color: label,
                                fontSize: 17,
                                fontWeight: isUnread ? .w600 : .w400,
                              ),
                              maxLines: 1,
                              overflow: .ellipsis,
                            ),
                          ),
                          if (room.isMuted)
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Icon(
                                CupertinoIcons.bell_slash_fill,
                                size: 14,
                                color: secondary,
                              ),
                            ),
                          const SizedBox(width: 6),
                          Text(
                            messageTimeText(room.lastTime),
                            style: TextStyle(color: secondary, fontSize: 13),
                          ),
                          const SizedBox(width: 3),
                          Icon(
                            CupertinoIcons.chevron_right,
                            size: 12,
                            color: tertiary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        room.lastMessage,
                        style: TextStyle(
                          color: secondary,
                          fontSize: 15,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: .ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
