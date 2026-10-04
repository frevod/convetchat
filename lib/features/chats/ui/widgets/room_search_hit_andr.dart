import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/utils/message_format.dart';
import 'package:convetchat/core/widgets/mxc_avatar.dart';
import 'package:convetchat/features/chats/domain/entities/chat_room.dart';
import 'package:go_router/go_router.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

class const RoomSearchHitAndr({
  super.key,
  required final ChatRoom room,
  required final M3ESearchController searchController,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return M3EListItem(
      headline: room.displayName,
      supportingText: room.lastMessage.isEmpty ? null : room.lastMessage,
      largeLeading: true,
      leading: MxcAvatar(
        mxc: room.avatarMxc,
        fallback: avatarInitial(room.displayName),
        size: 40,
        context: context,
      ),
      onTap: () {
        searchController.closeView(room.displayName);
        getIt<GoRouter>().push('/chat/${room.id}');
      },
    );
  }
}
