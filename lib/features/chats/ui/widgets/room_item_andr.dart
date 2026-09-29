import 'package:convetchat/core/utils/message_format.dart';
import 'package:convetchat/core/widgets/mxc_avatar.dart';
import 'package:convetchat/features/chats/domain/entities/chat_room.dart';
import 'package:convetchat/features/chats/ui/widgets/message_time_text.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

class const RoomItemAndr({super.key, required final ChatRoom room})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final initial = avatarInitial(room.displayName);
    return ListTile(
      leading: Stack(
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
                  color: Theme.of(context).colorScheme.primary,
                  shape: .circle,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.surface,
                    width: 2.5,
                  ),
                ),
              ),
            ),
        ],
      ),
      title: Text(room.displayName, maxLines: 1, overflow: .ellipsis),
      subtitle: Text(room.lastMessage, maxLines: 1, overflow: .ellipsis),
      trailing: Column(
        mainAxisAlignment: .center,
        crossAxisAlignment: .end,
        children: [
          Text(
            messageTimeText(room.lastTime),
            style: Theme.of(context).textTheme.labelSmall,
          ),
          if (room.unreadCount > 0) ...[
            const SizedBox(height: 4),
            Badge.count(
              count: room.unreadCount,
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          ],
        ],
      ),
      onTap: () => context.push('/chat/${room.id}'),
    );
  }
}
