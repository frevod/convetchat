import 'dart:async';
import 'dart:typed_data';

import 'package:convetchat/core/matrix/event_label.dart';
import 'package:convetchat/features/chats/domain/entities/chat_room.dart';
import 'package:convetchat/features/chats/domain/entities/connection_status.dart';
import 'package:convetchat/features/chats/domain/entities/searched_user.dart';
import 'package:convetchat/features/chats/domain/repositories/chats_repository.dart';
import 'package:matrix/matrix.dart';

class ChatsRepositoryImpl(final Client _client) implements ChatsRepository {
  @override
  Future<void> firstSync() async {
    try {
      await _client.onSync.stream.first.timeout(const Duration(seconds: 5));
    } on TimeoutException {
      return;
    }
  }

  @override
  Stream<({List<ChatRoom> rooms, List<ChatRoom> invites})> watchRooms() async* {
    yield _snapshot();
    final updates = StreamController<void>.broadcast();
    final onSyncSub = _client.onSync.stream.listen((_) => updates.add(null));
    final presenceSub = _client.onPresenceChanged.stream.listen(
      (_) => updates.add(null),
    );
    try {
      await for (final _ in updates.stream) {
        yield _snapshot();
      }
    } finally {
      await onSyncSub.cancel();
      await presenceSub.cancel();
      await updates.close();
    }
  }

  @override
  Stream<ConnectionStatus> watchConnectionStatus() {
    return _client.onSyncStatus.stream.map(_mapConnectionStatus);
  }

  ConnectionStatus _mapConnectionStatus(SyncStatusUpdate update) {
    return switch (update.status) {
      SyncStatus.error => ConnectionStatus.disconnected,
      _ => ConnectionStatus.connected,
    };
  }

  ({List<ChatRoom> rooms, List<ChatRoom> invites}) _snapshot() {
    final rooms = <ChatRoom>[];
    final invites = <ChatRoom>[];
    for (final room in _client.rooms) {
      final lastEvent = room.lastEvent;

      final partnerId = room.directChatMatrixID;
      // ignore: deprecated_member_use
      final presence = partnerId == null ? null : _client.presences[partnerId];
      final online =
          partnerId != null &&
          (presence?.presence == PresenceType.online ||
              presence?.currentlyActive == true);

      final preview = lastEvent == null
          ? ''
          : eventPreviewLabel(
              lastEvent,
              showSender: !room.isDirectChat,
            ).replaceAll('\n', ' ').trim();
      final chat = ChatRoom(
        id: room.id,
        displayName: room.getLocalizedDisplayname(),
        lastMessage: preview,
        lastTime: lastEvent?.originServerTs,
        unreadCount: room.notificationCount,
        avatarMxc: room.avatar?.toString(),
        isDirect: room.isDirectChat,
        online: online,
      );
      if (room.membership == Membership.join) {
        rooms.add(chat);
      } else if (room.membership == Membership.invite) {
        invites.add(chat);
      }
    }

    rooms.sort((a, b) {
      final at = a.lastTime;
      final bt = b.lastTime;
      if (at == null && bt == null) return 0;
      if (at == null) return 1;
      if (bt == null) return -1;
      return bt.compareTo(at);
    });
    return (rooms: rooms, invites: invites);
  }

  @override
  Future<List<SearchedUser>> searchUsers(String query) async {
    final response = await _client.searchUserDirectory(query);
    final results = response.results
        .map(
          (profile) => SearchedUser(
            userId: profile.userId,
            displayName: (profile.displayName?.isNotEmpty ?? false)
                ? profile.displayName!
                : profile.userId,
          ),
        )
        .toList();

    if (query.isValidMatrixIdStrict() &&
        query.sigil == '@' &&
        !results.any((user) => user.userId == query)) {
      results.add(SearchedUser(userId: query, displayName: query));
    }
    return results;
  }

  @override
  Future<String> createDirectChat(String userId) {
    return _client.startDirectChat(userId);
  }

  @override
  Future<String> createGroup({
    String? name,
    required bool isPublic,
    required bool showInDirectory,
    Uint8List? avatarBytes,
    String? avatarFilename,
  }) async {
    Uri? avatarUrl;
    final bytes = avatarBytes;
    if (bytes != null && bytes.isNotEmpty) {
      avatarUrl = await _client.uploadContent(
        bytes,
        filename: avatarFilename ?? 'avatar.jpg',
      );
    }

    final trimmed = name?.trim();
    return _client.createGroupChat(
      groupName: (trimmed == null || trimmed.isEmpty) ? null : trimmed,
      preset: isPublic
          ? CreateRoomPreset.publicChat
          : CreateRoomPreset.privateChat,
      visibility: showInDirectory ? Visibility.public : Visibility.private,
      groupCall: !isPublic,
      initialState: [
        if (avatarUrl != null)
          StateEvent(
            type: EventTypes.RoomAvatar,
            content: {'url': avatarUrl.toString()},
          ),
      ],
    );
  }

  @override
  Future<void> acceptInvite(String roomId) async {
    final room = _client.getRoomById(roomId);
    if (room == null) return;
    final wait = _client.waitForRoomInSync(roomId, join: true);
    await room.join();

    await wait.timeout(const Duration(seconds: 30));
  }

  @override
  Future<void> declineInvite(String roomId) async {
    await _client.getRoomById(roomId)?.leave();
  }
}
