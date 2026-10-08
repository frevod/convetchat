import 'package:convetchat/core/utils/message_format.dart';
import 'package:convetchat/core/widgets/mxc_avatar.dart';
import 'package:convetchat/features/chats/domain/entities/public_room.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

class const PublicRoomHitAndr({
  super.key,
  required final PublicRoom room,
  required final Future<void> Function() onPreview,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final subtitle = room.topic.isEmpty
        ? '${room.memberCount} уч.'
        : '${room.topic} • ${room.memberCount} уч.';
    return M3EListItem(
      headline: room.name,
      supportingText: subtitle,
      largeLeading: true,
      leading: MxcAvatar(
        mxc: room.avatarMxc,
        fallback: avatarInitial(room.name),
        size: 40,
        context: context,
      ),
      trailing: const Icon(Icons.login_rounded),
      onTap: onPreview,
    );
  }
}
