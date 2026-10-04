import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/utils/message_format.dart';
import 'package:convetchat/core/widgets/mxc_avatar.dart';
import 'package:convetchat/features/chats/domain/entities/searched_message.dart';
import 'package:convetchat/features/chats/ui/widgets/message_time_text.dart';
import 'package:go_router/go_router.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

class const MessageSearchHitAndr({
  super.key,
  required final SearchedMessage hit,
  required final M3ESearchController searchController,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final preview = hit.body.isEmpty
        ? hit.senderName
        : '${hit.senderName}: ${hit.body}';
    return M3EListItem(
      headline: hit.roomName,
      supportingText: preview,
      largeLeading: true,
      leading: MxcAvatar(
        mxc: null,
        fallback: avatarInitial(hit.roomName),
        size: 40,
        context: context,
      ),
      trailingText: messageTimeText(hit.timestamp),
      onTap: () {
        searchController.closeView(hit.body);
        getIt<GoRouter>().push('/chat/${hit.roomId}', extra: hit.eventId);
      },
    );
  }
}
