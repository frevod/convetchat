import 'package:convetchat/app/adaptive/adaptive_loading_indicator.dart';
import 'package:convetchat/core/utils/message_format.dart';
import 'package:convetchat/features/chats/domain/entities/searched_user.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

class const PersonSearchHitAndr({
  super.key,
  required final SearchedUser user,
  required final bool busy,
  required final Future<void> Function() onTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return M3EListItem(
      headline: user.displayName,
      supportingText: user.userId,
      largeLeading: true,
      leading: M3EListAvatar(label: avatarInitial(user.displayName)),
      trailing: busy
          ? const SizedBox.square(
              dimension: 20,
              child: AdaptiveLoadingIndicator(),
            )
          : const Icon(Icons.chat_bubble_outline_rounded),
      onTap: busy ? null : onTap,
    );
  }
}
