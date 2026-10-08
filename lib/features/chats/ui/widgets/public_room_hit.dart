import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/platform_style.dart';
import 'package:convetchat/features/chats/domain/entities/public_room.dart';
import 'package:convetchat/features/chats/ui/widgets/public_room_hit_andr.dart';
import 'package:convetchat/features/chats/ui/widgets/public_room_hit_cup.dart';
import 'package:convetchat/features/chats/ui/widgets/room_preview_sheet.dart';
import 'package:flutter/widgets.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

class const PublicRoomHit({
  super.key,
  required final PublicRoom room,
  required final Future<void> Function() onPreview,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (getIt<PlatformStyle>().isCupertino) {
      return PublicRoomHitCup(room: room, onPreview: onPreview);
    }
    return PublicRoomHitAndr(room: room, onPreview: onPreview);
  }
}

Future<void> openPublicRoomPreview({
  required BuildContext context,
  required PublicRoom room,
  M3ESearchController? searchController,
}) {
  return openRoomPreviewSheet(
    context: context,
    roomIdOrAlias: room.roomId,
    fallback: room,
    searchController: searchController,
  );
}
