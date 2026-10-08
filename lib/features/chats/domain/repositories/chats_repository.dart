import 'dart:typed_data';

import 'package:convetchat/features/chats/domain/entities/chat_room.dart';
import 'package:convetchat/features/chats/domain/entities/connection_status.dart';
import 'package:convetchat/features/chats/domain/entities/notification_mode.dart';
import 'package:convetchat/features/chats/domain/entities/public_room.dart';
import 'package:convetchat/features/chats/domain/entities/room_preview.dart';
import 'package:convetchat/features/chats/domain/entities/searched_message.dart';
import 'package:convetchat/features/chats/domain/entities/searched_user.dart';

abstract class ChatsRepository() {
  Stream<({List<ChatRoom> rooms, List<ChatRoom> invites})> watchRooms();

  Stream<ConnectionStatus> watchConnectionStatus();

  Future<void> firstSync();

  Future<List<SearchedUser>> searchUsers(String query);

  Future<List<SearchedUser>> directChatPartners();

  Future<List<SearchedMessage>> searchMessages(String query);

  Future<List<PublicRoom>> searchPublicRooms(String query);

  Future<String> joinRoom(String roomId);

  Future<RoomPreview> fetchRoomPreview(String roomIdOrAlias);

  Future<String> knockRoom(String roomId);

  Future<void> cancelKnock(String roomId);

  Future<String> createDirectChat(String userId);

  Future<String> createGroup({
    String? name,
    required bool isPublic,
    required bool showInDirectory,
    Uint8List? avatarBytes,
    String? avatarFilename,
  });

  Future<void> acceptInvite(String roomId);

  Future<void> declineInvite(String roomId);

  Future<void> inviteUser(String roomId, String userId, {String? reason});

  Future<void> setMuted(String roomId, bool muted);

  Future<bool> isRoomMuted(String roomId);

  Future<void> setNotificationMode(String roomId, NotificationMode mode);

  Stream<Set<String>> watchMentionsOnlyRooms();

  Future<bool> mentionsOnlySupported();

  Future<void> setPinned(String roomId, bool pinned);

  Future<void> leaveRoom(String roomId);
}
