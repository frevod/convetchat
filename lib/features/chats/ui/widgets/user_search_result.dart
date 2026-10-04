import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/platform_style.dart';
import 'package:convetchat/core/utils/message_format.dart';
import 'package:convetchat/features/chats/ui/widgets/user_search_result_andr.dart';
import 'package:convetchat/features/chats/ui/widgets/user_search_result_cup.dart';
import 'package:flutter/widgets.dart';

class const UserSearchResult({
  super.key,
  required final String displayName,
  required final String userId,
  required final VoidCallback onTap,

  final bool showLoading = false,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (getIt<PlatformStyle>().isCupertino) {
      return UserSearchResultCup(
        displayName: displayName,
        userId: userId,
        initial: avatarInitial(displayName),
        onTap: onTap,
        showLoading: showLoading,
      );
    }
    return UserSearchResultAndr(
      displayName: displayName,
      userId: userId,
      onTap: onTap,
    );
  }
}
