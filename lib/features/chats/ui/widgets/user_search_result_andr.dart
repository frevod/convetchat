import 'package:convetchat/core/utils/message_format.dart';
import 'package:material_ui/material_ui.dart';

class const UserSearchResultAndr({
  super.key,
  required final String displayName,
  required final String userId,
  required final VoidCallback onTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final initial = avatarInitial(displayName);
    return ListTile(
      leading: CircleAvatar(child: Text(initial)),
      title: Text(displayName, maxLines: 1, overflow: .ellipsis),
      subtitle: Text(userId, maxLines: 1, overflow: .ellipsis),
      onTap: onTap,
    );
  }
}
