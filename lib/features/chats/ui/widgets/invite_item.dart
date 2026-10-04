import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/platform_style.dart';
import 'package:convetchat/features/chats/domain/entities/chat_room.dart';
import 'package:convetchat/features/chats/ui/widgets/invite_item_andr.dart';
import 'package:convetchat/features/chats/ui/widgets/invite_item_cup.dart';
import 'package:flutter/widgets.dart';

class const InviteItem({
  super.key,
  required final ChatRoom invite,
  required final bool busy,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (getIt<PlatformStyle>().isCupertino) {
      return InviteItemCup(invite: invite, busy: busy);
    }
    return InviteItemAndr(invite: invite, busy: busy);
  }
}
