import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/platform_style.dart';
import 'package:convetchat/features/chats/domain/entities/chat_room.dart';
import 'package:convetchat/features/chats/ui/widgets/room_item_andr.dart';
import 'package:convetchat/features/chats/ui/widgets/room_item_cup.dart';
import 'package:flutter/widgets.dart';

class const RoomItem({super.key, required final ChatRoom room})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (getIt<PlatformStyle>().isCupertino) {
      return RoomItemCup(room: room);
    }
    return RoomItemAndr(room: room);
  }
}
