import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/platform_style.dart';
import 'package:convetchat/features/chats/domain/entities/public_room.dart';
import 'package:convetchat/features/chats/ui/cubit/chat_search_cubit.dart';
import 'package:convetchat/features/chats/ui/widgets/public_room_hit_andr.dart';
import 'package:convetchat/features/chats/ui/widgets/public_room_hit_cup.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

class const PublicRoomHit({
  super.key,
  required final PublicRoom room,
  required final bool busy,
  required final Future<void> Function() onJoin,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (getIt<PlatformStyle>().isCupertino) {
      return PublicRoomHitCup(room: room, busy: busy, onJoin: onJoin);
    }
    return PublicRoomHitAndr(room: room, busy: busy, onJoin: onJoin);
  }
}

Future<void> joinAndOpenPublicRoom({
  required ChatSearchCubit searchCubit,
  required PublicRoom room,
  M3ESearchController? searchController,
}) async {
  final roomId = await searchCubit.joinPublicRoom(room.roomId);
  if (roomId == null) return;
  final controller = searchController;
  if (controller != null && controller.isOpen) {
    controller.closeView(room.name);
  }
  getIt<GoRouter>().push('/chat/$roomId');
}
