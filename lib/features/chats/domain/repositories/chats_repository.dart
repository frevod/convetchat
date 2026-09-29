import 'dart:typed_data';

import 'package:convetchat/features/chats/domain/entities/chat_room.dart';
import 'package:convetchat/features/chats/domain/entities/connection_status.dart';
import 'package:convetchat/features/chats/domain/entities/searched_user.dart';

abstract class ChatsRepository() {
  Stream<({List<ChatRoom> rooms, List<ChatRoom> invites})> watchRooms();

  Stream<ConnectionStatus> watchConnectionStatus();

  Future<void> firstSync();

  Future<List<SearchedUser>> searchUsers(String query);

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
}
