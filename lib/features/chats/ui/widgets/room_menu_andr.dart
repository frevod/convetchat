import 'package:convetchat/app/adaptive/adaptive_dialog.dart';
import 'package:convetchat/features/chats/domain/entities/chat_room.dart';
import 'package:convetchat/features/chats/ui/cubit/chats_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

abstract final class RoomMenuAndr() {
  static Future<void> show(
    BuildContext context,
    ChatRoom room,
    Rect anchor,
  ) async {
    final action = await showM3EMenu<String>(
      context: context,
      anchor: anchor,
      position: .bottomStart,
      children: [
        M3EMenuEntry(
          value: 'mute',
          label: room.isMuted
              ? 'Включить уведомления'
              : 'Отключить уведомления',
          leading: Icon(
            room.isMuted
                ? Icons.notifications_rounded
                : Icons.notifications_off_rounded,
          ),
        ),
        M3EMenuEntry(
          value: 'pin',
          label: room.isPinned ? 'Открепить' : 'Закрепить',
          leading: Icon(
            room.isPinned ? Icons.push_pin_outlined : Icons.push_pin_rounded,
          ),
        ),
        const M3EMenuDivider(),
        const M3EMenuEntry(
          value: 'leave',
          label: 'Покинуть комнату',
          leading: Icon(Icons.logout_rounded),
          isDestructive: true,
        ),
      ],
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
}
