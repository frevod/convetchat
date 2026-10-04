import 'package:convetchat/app/adaptive/adaptive_dialog.dart';
import 'package:convetchat/core/utils/message_format.dart';
import 'package:convetchat/core/widgets/mxc_avatar.dart';
import 'package:convetchat/features/chats/domain/entities/chat_room.dart';
import 'package:convetchat/features/chats/ui/cubit/chats_cubit.dart';
import 'package:convetchat/features/chats/ui/widgets/message_time_text.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

Future<bool> _confirmLeaveRoom(BuildContext context, ChatRoom room) {
  return AdaptiveDialog.confirm(
    context: context,
    title: 'Покинуть комнату?',
    message: 'Вы перестанете получать сообщения из «${room.displayName}».',
    confirmLabel: 'Покинуть',
    isDestructive: true,
  );
}

M3EListItem buildRoomListItem(
  BuildContext context,
  ChatRoom room, {
  Key? key,
  void Function(String roomId, BuildContext rowContext)? onRowContext,
}) {
  final initial = avatarInitial(room.displayName);
  final scheme = Theme.of(context).colorScheme;
  final cubit = context.read<ChatsCubit>();

  return M3EListItem(
    key: key,
    headline: room.displayName,
    supportingText: room.lastMessage.isEmpty ? null : room.lastMessage,
    largeLeading: true,
    leading: Builder(
      builder: (rowContext) {
        onRowContext?.call(room.id, rowContext);
        return Stack(
          clipBehavior: .none,
          children: [
            MxcAvatar(
              mxc: room.avatarMxc,
              fallback: initial,
              size: 48,
              context: context,
            ),
            if (room.isDirect && room.online)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 15,
                  height: 15,
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    shape: .circle,
                    border: Border.all(color: scheme.surface, width: 2.5),
                  ),
                ),
              ),
          ],
        );
      },
    ),
    trailingText: messageTimeText(room.lastTime),
    trailing: (room.unreadCount > 0 || room.isMuted || room.isPinned)
        ? Column(
            mainAxisSize: .min,
            crossAxisAlignment: .end,
            children: [
              if (room.isPinned || room.isMuted)
                Row(
                  mainAxisSize: .min,
                  children: [
                    if (room.isPinned)
                      const Icon(
                        Icons.push_pin_rounded,
                        size: 16,
                        semanticLabel: 'Закреплено',
                      ),
                    if (room.isMuted)
                      const Icon(
                        Icons.notifications_off_rounded,
                        size: 16,
                        semanticLabel: 'Уведомления отключены',
                      ),
                  ],
                ),
              if (room.unreadCount > 0) ...[
                const SizedBox(height: 4),
                Badge.count(
                  count: room.unreadCount,
                  backgroundColor: scheme.primary,
                ),
              ],
            ],
          )
        : const SizedBox.shrink(),
    onTap: () => context.push('/chat/${room.id}'),
    swipe: M3EListItemSwipe(
      mode: .reveal,
      leading: [
        M3EListSwipeAction(
          icon: Icon(
            room.isPinned ? Icons.push_pin_outlined : Icons.push_pin_rounded,
          ),
          isPrimary: true,
          onPressed: () => cubit.togglePin(room),
        ),
      ],
      trailing: [
        M3EListSwipeAction(
          icon: const Icon(Icons.logout_rounded),
          backgroundColor: scheme.error,
          foregroundColor: scheme.onError,
          isPrimary: true,
          onPressed: () async {
            if (!await _confirmLeaveRoom(context, room)) return;
            cubit.leaveRoom(room);
          },
        ),
      ],
    ),
  );
}
