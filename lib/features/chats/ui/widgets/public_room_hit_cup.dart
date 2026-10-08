import 'package:convetchat/core/utils/message_format.dart';
import 'package:convetchat/features/chats/domain/entities/public_room.dart';
import 'package:cupertino_ui/cupertino_ui.dart';

class const PublicRoomHitCup({
  super.key,
  required final PublicRoom room,
  required final Future<void> Function() onPreview,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final avatarBg = CupertinoColors.systemGrey5.resolveFrom(context);
    final subColor = CupertinoColors.systemGrey.resolveFrom(context);
    final subtitle = room.topic.isEmpty
        ? '${room.memberCount} уч.'
        : '${room.topic} • ${room.memberCount} уч.';
    return GestureDetector(
      behavior: .opaque,
      onTap: onPreview,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: .center,
              decoration: BoxDecoration(color: avatarBg, shape: .circle),
              child: Text(
                avatarInitial(room.name),
                style: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: .start,
                children: [
                  Text(
                    room.name,
                    maxLines: 1,
                    overflow: .ellipsis,
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: .ellipsis,
                    style: TextStyle(fontSize: 13, color: subColor),
                  ),
                ],
              ),
            ),
            Icon(CupertinoIcons.arrow_right_circle, color: subColor),
          ],
        ),
      ),
    );
  }
}
