import 'dart:async';
import 'dart:typed_data';

import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/matrix/event_label.dart';
import 'package:convetchat/core/matrix/matrix_call_failure.dart';
import 'package:convetchat/core/utils/safe_text.dart';
import 'package:convetchat/features/chats/domain/entities/chat_room.dart';
import 'package:convetchat/features/chats/domain/entities/connection_status.dart';
import 'package:convetchat/features/chats/domain/entities/public_room.dart';
import 'package:convetchat/features/chats/domain/entities/searched_message.dart';
import 'package:convetchat/features/chats/domain/entities/searched_user.dart';
import 'package:convetchat/features/chats/domain/repositories/chats_repository.dart';
import 'package:http/http.dart' as http;
import 'package:matrix/matrix.dart';
import 'package:talker_flutter/talker_flutter.dart';

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
      final disp = room.getLocalizedDisplayname();
      final chat = ChatRoom(
        id: room.id,
        displayName: disp,
        lastMessage: preview,
        lastTime: lastEvent?.originServerTs,
        unreadCount: room.notificationCount,
        avatarMxc: room.avatar?.toString(),
        isDirect: room.isDirectChat,
        online: online,
        isMuted: room.pushRuleState == PushRuleState.dontNotify,
        isPinned: room.isFavourite,
      );
      if (room.membership == Membership.join) {
        rooms.add(chat);
      } else if (room.membership == Membership.invite) {
        invites.add(chat);
      }
    }

    rooms.sort((a, b) {
      if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
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
  Future<List<SearchedMessage>> searchMessages(String query) async {
    try {
      final hits = await _serverSearchMessages(query);
      if (hits.isNotEmpty) return hits;
      getIt<Talker>().warning('[chats] server message search empty, local fallback');
    } catch (e, s) {
      getIt<Talker>().warning(
        '[chats] server message search failed, local fallback',
        e,
        s,
      );
    }
    return _localSearchMessages(query);
  }

  Future<List<SearchedMessage>> _serverSearchMessages(String query) async {
    final response = await _client.search(
      Categories(
        roomEvents: RoomEventsCriteria(
          searchTerm: query,
          orderBy: SearchOrder.recent,
        ),
      ),
    );
    final results = response.searchCategories.roomEvents?.results ?? [];
    final hits = <SearchedMessage>[];
    for (final hit in results) {
      final event = hit.result;
      final roomId = event?.roomId;
      if (event == null || roomId == null) continue;
      final body = event.content['body'];
      final room = _client.getRoomById(roomId);
      final cleanBody = body is String
          ? stripReplyFallback(body).replaceAll('\n', ' ').trim()
          : '';
      hits.add(
        SearchedMessage(
          roomId: roomId,
          eventId: event.eventId,
          roomName: room?.getLocalizedDisplayname() ?? roomId,
          senderName: room == null
              ? event.senderId
              : _senderName(room, event.senderId),
          body: cleanBody,
          timestamp: event.originServerTs,
        ),
      );
    }
    return hits;
  }

  Future<List<SearchedMessage>> _localSearchMessages(String query) async {
    final hits = <SearchedMessage>[];
    for (final room in _client.rooms) {
      if (room.membership != Membership.join || room.isSpace) continue;
      try {
        final found = await room.searchEvents(searchTerm: query, limit: 200);
        for (final event in found.events) {
          hits.add(
            SearchedMessage(
              roomId: room.id,
              eventId: event.eventId,
              roomName: room.getLocalizedDisplayname(),
              senderName: _senderName(room, event.senderId),
              body: eventLabel(event).replaceAll('\n', ' ').trim(),
              timestamp: event.originServerTs,
            ),
          );
        }
      } catch (e, s) {
        getIt<Talker>().warning(
          '[chats] local message search failed in room ${room.id}',
          e,
          s,
        );
      }
      if (hits.length >= 50) break;
    }
    hits.sort((a, b) {
      final at = a.timestamp;
      final bt = b.timestamp;
      if (at == null && bt == null) return 0;
      if (at == null) return 1;
      if (bt == null) return -1;
      return bt.compareTo(at);
    });
    return hits.take(50).toList();
  }

  static String _senderName(Room room, String senderId) {
    final name = room
        .unsafeGetUserFromMemoryOrFallback(senderId)
        .calcDisplayname();
    if (name.isNotEmpty) return sanitizeForText(name);
    final local = senderId.split(':').first;
    final fallback = local.startsWith('@') ? local.substring(1) : senderId;
    return sanitizeForText(fallback);
  }

  @override
  Future<List<PublicRoom>> searchPublicRooms(String query) async {
    final trimmed = query.trim();
    final chunk = (await _client.queryPublicRooms(
      filter: trimmed.isEmpty
          ? null
          : PublicRoomQueryFilter(genericSearchTerm: trimmed),
      limit: trimmed.isEmpty ? 100 : 50,
    )).chunk;
    final rooms = [
      for (final c in chunk)
        PublicRoom(
          roomId: c.roomId,
          name: (c.name?.isNotEmpty ?? false)
              ? c.name!
              : (c.canonicalAlias ?? c.roomId),
          topic: (c.topic ?? '').replaceAll('\n', ' ').trim(),
          avatarMxc: c.avatarUrl?.toString(),
          memberCount: c.numJoinedMembers,
        ),
    ];
    if (trimmed.isValidMatrixIdStrict() &&
        trimmed.sigil == '#' &&
        !rooms.any((room) => room.roomId == trimmed)) {
      try {
        final res = await _client.queryPublicRooms(
          server: trimmed.domain,
          filter: PublicRoomQueryFilter(genericSearchTerm: trimmed),
        );
        final found = res.chunk.where((c) => c.canonicalAlias == trimmed);
        if (found.isNotEmpty) {
          final c = found.first;
          rooms.insert(
            0,
            PublicRoom(
              roomId: c.roomId,
              name: (c.name?.isNotEmpty ?? false)
                  ? c.name!
                  : (c.canonicalAlias ?? c.roomId),
              topic: (c.topic ?? '').replaceAll('\n', ' ').trim(),
              avatarMxc: c.avatarUrl?.toString(),
              memberCount: c.numJoinedMembers,
            ),
          );
        }
      } catch (e, s) {
        getIt<Talker>().warning('[chats] resolve alias failed: $trimmed', e, s);
      }
    }
    return rooms;
  }

  @override
  Future<String> joinRoom(String roomId) async {
    final wait = _client.waitForRoomInSync(roomId, join: true);
    await _joinRoom(roomId);
    await wait.timeout(const Duration(seconds: 30));
    return roomId;
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
    if (room == null) {
      throw StateError('Приглашение не найдено: $roomId');
    }
    final dmId = room.directChatMatrixID;
    if (dmId != null) {
      await room.addToDirectChat(dmId);
    }
    final wait = _client.waitForRoomInSync(roomId, join: true);

    await _joinRoom(roomId);

    await wait.timeout(const Duration(seconds: 30));

    if (dmId != null) {
      final joined = _client.getRoomById(roomId);
      if (joined != null && joined.directChatMatrixID == null) {
        await joined.addToDirectChat(dmId);
      }
    }
  }

  static const _joinTimeout = Duration(seconds: 30);

  Future<void> _joinRoom(String roomId) async {
    final homeserver = _client.homeserver;
    if (homeserver == null) {
      throw const MatrixCallFailure(
        method: 'POST',
        path: '/join',
        statusCode: null,
        error: 'Homeserver не определён',
      );
    }
    final uri = homeserver.resolveUri(
      Uri(path: '_matrix/client/v3/rooms/${Uri.encodeComponent(roomId)}/join'),
    );

    late final http.Response response;
    try {
      response = await http
          .post(
            uri,
            headers: {
              if (_client.accessToken case final token?)
                'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: '{}',
          )
          .timeout(_joinTimeout);
    } on Object catch (e) {
      throw MatrixCallFailure.from(e, method: 'POST', path: uri.path);
    }

    if (response.statusCode != 200) {
      throw MatrixCallFailure.fromHttp(
        response,
        method: 'POST',
        path: uri.path,
      );
    }
  }

  @override
  Future<void> declineInvite(String roomId) async {
    await _client.getRoomById(roomId)?.leave();
  }

  @override
  Future<void> setMuted(String roomId, bool muted) async {
    final room = _client.getRoomById(roomId);
    if (room == null) {
      throw StateError('Комната не найдена: $roomId');
    }
    try {
      await room.setPushRuleState(
        muted ? PushRuleState.dontNotify : PushRuleState.notify,
      );
    } on MatrixException catch (e) {
      if (e.error != MatrixError.M_NOT_FOUND) rethrow;
      try {
        await _client.oneShotSync().timeout(const Duration(seconds: 15));
      } catch (_) {}
      try {
        await room.setPushRuleState(
          muted ? PushRuleState.dontNotify : PushRuleState.notify,
        );
      } on MatrixException catch (e) {
        if (e.error != MatrixError.M_NOT_FOUND) rethrow;
      }
    }
  }

  @override
  Future<void> setPinned(String roomId, bool pinned) async {
    final room = _client.getRoomById(roomId);
    if (room == null) {
      throw StateError('Комната не найдена: $roomId');
    }
    await room.setFavourite(pinned);
  }

  @override
  Future<void> leaveRoom(String roomId) async {
    final room = _client.getRoomById(roomId);
    if (room == null) {
      throw StateError('Комната не найдена: $roomId');
    }
    await room.leave();
  }
}
