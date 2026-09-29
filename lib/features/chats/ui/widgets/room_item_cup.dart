import 'package:convetchat/core/utils/message_format.dart';
import 'package:convetchat/core/widgets/mxc_avatar.dart';
import 'package:convetchat/features/chats/domain/entities/chat_room.dart';
import 'package:convetchat/features/chats/ui/widgets/message_time_text.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:go_router/go_router.dart';

class const RoomItemCup({super.key, required final ChatRoom room})
    extends StatelessWidget {
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
                    if (room.isDirect && room.online)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 15,
                          height: 15,
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemBlue.resolveFrom(
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
