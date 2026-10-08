import 'dart:async';

import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/matrix/server_capabilities.dart';
import 'package:convetchat/core/widgets/user_preview_sheet.dart';
import 'package:convetchat/features/chats/ui/widgets/room_preview_sheet.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:matrix/matrix.dart';
import 'package:talker_flutter/talker_flutter.dart';

bool isMatrixLink(Uri uri) {
  if (uri.scheme == 'matrix') return true;
  final scheme = uri.scheme;
  return (scheme == 'https' || scheme == 'http') &&
      uri.host.toLowerCase() == 'matrix.to';
}

Future<bool> openMatrixLink(BuildContext context, Uri uri) async {
  final parts = _normalizeMatrixUri(uri.toString()).parseIdentifierIntoParts();
  if (parts == null) return false;
  final primary = parts.primaryIdentifier;
  if (primary.startsWith('@')) {
    await _openUser(context, primary);
    return true;
  }
  if (primary.startsWith('!') || primary.startsWith('#')) {
    return _openRoom(context, primary);
  }
  return false;
}

final _matrixSigilPrefix = RegExp(r'^matrix:(u|r|roomid|e)/([@#!$])');

String _normalizeMatrixUri(String raw) {
  return raw.replaceFirstMapped(_matrixSigilPrefix, (m) => 'matrix:${m[1]}/');
}

Future<bool> _openRoom(BuildContext context, String target) async {
  final client = getIt<Client>();
  try {
    final known = target.startsWith('!')
        ? client.getRoomById(target)
        : client.getRoomByAlias(target);
    if (known != null && known.membership == Membership.join) {
      getIt<GoRouter>().push('/chat/${known.id}');
      return true;
    }
    if (await ServerCapabilities.roomSummarySupported(client)) {
      if (!context.mounted) return false;
      await openRoomPreviewSheet(context: context, roomIdOrAlias: target);
      return true;
    }
    final roomId = await client
        .joinRoomById(target)
        .timeout(const Duration(seconds: 30));
    await client
        .waitForRoomInSync(roomId, join: true)
        .timeout(const Duration(seconds: 30));
    getIt<GoRouter>().push('/chat/$roomId');
    return true;
  } catch (e, s) {
    getIt<Talker>().warning('[chat] open room link failed: $target', e, s);
    return false;
  }
}

Future<void> _openUser(BuildContext context, String userId) {
  return openUserPreviewSheet(context, userId);
}
