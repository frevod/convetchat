import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/matrix/event_label.dart';
import 'package:convetchat/core/matrix/matrix_call_failure.dart';
import 'package:convetchat/core/matrix/ru_matrix_localizations.dart';
import 'package:convetchat/core/utils/safe_text.dart';
import 'package:convetchat/features/chat/domain/entities/chat_message.dart';
import 'package:convetchat/features/chat/domain/entities/chat_send_restriction.dart';
import 'package:convetchat/features/chat/domain/entities/media_attachment.dart';
import 'package:convetchat/features/chat/domain/entities/room_info.dart';
import 'package:convetchat/features/chat/domain/entities/voice_message.dart';
import 'package:convetchat/features/chat/domain/repositories/chat_repository.dart';
import 'package:matrix/encryption.dart';
import 'package:matrix/matrix.dart';
import 'package:path/path.dart' as path_lib;
import 'package:path_provider/path_provider.dart';
import 'package:talker_flutter/talker_flutter.dart';

class ChatRepositoryImpl(final Client _client) implements ChatRepository {
  final Map<String, Timeline> _timelines = {};

  Room? _room(String roomId) => _client.getRoomById(roomId);

  @override
  String roomName(String roomId) =>
      _room(roomId)?.getLocalizedDisplayname() ?? 'Чат';

  @override
  String? roomAvatar(String roomId) {
    final room = _room(roomId);
    if (room == null) return null;
    final avatar = room.avatar;
    if (avatar != null) return avatar.toString();
    final partnerId = room.directChatMatrixID;
    if (partnerId != null) {
      return room
          .unsafeGetUserFromMemoryOrFallback(partnerId)
          .avatarUrl
          ?.toString();
    }
    return null;
  }

  @override
  String? directChatPartner(String roomId) => _room(roomId)?.directChatMatrixID;

  @override
  Stream<RoomInfo> watchRoomInfo(String roomId) async* {
    yield _roomInfoSnapshot(roomId);
    await for (final _ in _client.onSync.stream) {
      yield _roomInfoSnapshot(roomId);
    }
  }

  RoomInfo _roomInfoSnapshot(String roomId) {
    final room = _room(roomId);
    if (room == null) {
      return RoomInfo(roomId: roomId, name: 'Чат');
    }
    final alias = room.canonicalAlias;
    final members =
        room
            .getParticipants([Membership.join, Membership.invite])
            .map(
              (user) => RoomParticipant(
                id: user.id,
                displayName: user.calcDisplayname().trim().isEmpty
                    ? user.id
                    : user.calcDisplayname(),
                avatarMxc: user.avatarUrl?.toString(),
                invited: user.membership == Membership.invite,
              ),
            )
            .toList()
          ..sort((a, b) {
            if (a.invited != b.invited) return a.invited ? 1 : -1;
            return a.displayName.toLowerCase().compareTo(
              b.displayName.toLowerCase(),
            );
          });
    return RoomInfo(
      roomId: roomId,
      name: room.getLocalizedDisplayname(),
      topic: room.topic,
      avatarMxc: roomAvatar(roomId),
      canonicalAlias: alias.isEmpty ? null : alias,
      encrypted: room.encrypted,
      isDirect: room.isDirectChat,
      members: members,
    );
  }

  @override
  Future<void> leaveRoom(String roomId) async {
    final room = _room(roomId);
    if (room == null) return;
    await room.leave();
  }

  @override
  Stream<List<({String id, String name})>> watchTypingUsers(
    String roomId,
  ) async* {
    final room = _room(roomId);
    if (room == null) {
      yield const [];
      return;
    }
    final ownId = _client.userID;
    List<({String id, String name})> snapshot() {
      return room.typingUsers
          .where((user) => user.id != ownId)
          .map((user) => (id: user.id, name: _senderName(room, user.id)))
          .toList();
    }

    yield snapshot();
    await for (final _ in _client.onSync.stream) {
      yield snapshot();
    }
  }

  @override
  Stream<({bool online, DateTime? lastActive})> watchPartnerPresence(
    String roomId,
  ) async* {
    final room = _room(roomId);
    final partnerId = room?.directChatMatrixID;
    if (room == null || partnerId == null) {
      yield (online: false, lastActive: null);
      return;
    }
    ({bool online, DateTime? lastActive}) map([CachedPresence? p]) {
      final online =
          p?.presence == PresenceType.online || p?.currentlyActive == true;
      return (online: online, lastActive: p?.lastActiveTimestamp);
    }

    try {
      final cached = await _client.fetchCurrentPresence(
        partnerId,
        fetchOnlyFromCached: true,
      );
      yield map(cached);
    } catch (_) {
      yield (online: false, lastActive: null);
    }
    await for (final p in _client.onPresenceChanged.stream.where(
      (p) => p.userid == partnerId,
    )) {
      yield map(p);
    }
  }

  @override
  Future<void> setTyping(String roomId, bool isTyping) async {
    final room = _room(roomId);
    if (room == null) return;
    try {
      await room.setTyping(isTyping, timeout: 30000);
    } catch (_, s) {
      getIt<Talker>().handle(s);
    }
  }

  @override
  Stream<ChatSendRestriction> watchSendRestriction(String roomId) async* {
    final room = _room(roomId);
    if (room == null) {
      yield ChatSendRestriction.none;
      return;
    }
    ChatSendRestriction current() => _sendRestriction(room);
    yield current();
    await for (final _ in _client.onSync.stream) {
      yield current();
    }
  }

  ChatSendRestriction _sendRestriction(Room room) {
    if (room.isExtinct) return ChatSendRestriction.tombstoned;
    switch (room.membership) {
      case Membership.invite:
        return ChatSendRestriction.invitePending;
      case Membership.ban:
        return ChatSendRestriction.banned;
      case Membership.leave:
      case Membership.knock:
        return ChatSendRestriction.left;
      case Membership.join:
        break;
    }
    final others = room
        .getParticipants()
        .where((user) => user.id != _client.userID)
        .toList();
    if (others.isNotEmpty &&
        room.encrypted &&
        !others.any(
          (user) =>
              _client.userDeviceKeys[user.id]?.deviceKeys.values.isNotEmpty ==
              true,
        )) {
      return ChatSendRestriction.partnerUnavailable;
    }
    if (!room.canSendDefaultMessages) return ChatSendRestriction.noPermission;
    return ChatSendRestriction.none;
  }

  @override
  Stream<List<ChatMessage>> watchMessages(String roomId) async* {
    final room = _room(roomId);
    if (room == null) {
      yield [];
      return;
    }
    final updates = StreamController<void>.broadcast();
    StreamSubscription? syncSub;
    try {
      final timeline = await room.getTimeline(
        onUpdate: () {
          if (!updates.isClosed) updates.add(null);
        },
      );
      _timelines[roomId] = timeline;

      syncSub = _client.onSync.stream
          .where(
            (syncUpdate) =>
                syncUpdate.rooms?.join?[roomId]?.ephemeral?.any(
                  (ephemeral) => ephemeral.type == 'm.receipt',
                ) ??
                false,
          )
          .listen((_) {
            if (!updates.isClosed) updates.add(null);
          });

      unawaited(_prefetchHistory(timeline));

      _requestKeysIfNeeded(roomId, timeline);
      yield _snapshot(room, timeline);
      await for (final _ in updates.stream) {
        if (_hasUndecrypted(timeline)) {
          _requestKeysIfNeeded(roomId, timeline);
        }
        yield _snapshot(room, timeline);
      }
    } finally {
      await syncSub?.cancel();
      await updates.close();
    }
  }

  @override
  Future<void> loadMore(String roomId) async {
    final timeline = _timelines[roomId];

    if (timeline == null ||
        timeline.isRequestingHistory ||
        !timeline.canRequestHistory) {
      return;
    }
    await timeline.requestHistory(historyCount: 100);
  }

  static Future<void> _prefetchHistory(Timeline timeline) async {
    var rounds = 0;
    while (timeline.events.length < 50 &&
        rounds < 3 &&
        timeline.canRequestHistory &&
        !timeline.isRequestingHistory) {
      final before = timeline.events.length;
      await timeline.requestHistory(historyCount: 100);
      if (timeline.events.length == before) break;
      rounds++;
    }
  }

  @override
  Future<void> sendText({
    required String roomId,
    required String text,
    String? inReplyToEventId,
  }) async {
    final room = _room(roomId);
    if (room == null) throw Exception('Комната не найдена');
    await room.sendTextEvent(
      text,
      inReplyTo: _replyTarget(roomId, inReplyToEventId),
    );
  }

  @override
  Future<void> editText({
    required String roomId,
    required String eventId,
    required String text,
  }) async {
    final room = _room(roomId);
    if (room == null) throw Exception('Комната не найдена');
    await room.sendTextEvent(text, editEventId: eventId, parseCommands: false);
  }

  Event? _replyTarget(String roomId, String? inReplyToEventId) {
    if (inReplyToEventId == null) return null;
    final timeline = _timelines[roomId];
    if (timeline == null) return null;
    for (final event in timeline.events) {
      if (event.eventId == inReplyToEventId) return event;
    }
    return null;
  }

  @override
  Future<void> sendVoice({
    required String roomId,
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
    required int durationMs,
    required List<int> waveform,
    String? inReplyToEventId,
  }) async {
    final room = _room(roomId);
    if (room == null) throw Exception('Комната не найдена');
    final file = MatrixAudioFile(
      bytes: bytes,
      name: fileName,
      mimeType: mimeType,
      duration: durationMs,
    );
    await room.sendFileEvent(
      file,
      inReplyTo: _replyTarget(roomId, inReplyToEventId),
      extraContent: {
        'org.matrix.msc3245.voice': {},
        'org.matrix.msc1767.audio': {
          'duration': durationMs,
          'waveform': waveform,
        },
      },
    );
  }

  @override
  Future<void> sendMedia({
    required String roomId,
    required String filePath,
    required String fileName,
    required bool isVideo,
    int? width,
    int? height,
    int? durationMs,
    Uint8List? thumbBytes,
    int? thumbWidth,
    int? thumbHeight,
    String? caption,
    String? inReplyToEventId,
    bool isCircle = false,
  }) async {
    final room = _room(roomId);
    if (room == null) throw Exception('Комната не найдена');
    final bytes = await File(filePath).readAsBytes();
    if (bytes.length > maxUploadBytes) {
      throw MatrixCallFailure(
        method: 'POST',
        path: '/media/v3/upload',
        statusCode: null,
        errcode: 'M_TOO_LARGE',
        error:
            '${bytes.length ~/ (1024 * 1024)} МБ при лимите '
            '${maxUploadBytes ~/ (1024 * 1024)} МБ',
      );
    }
    final MatrixFile file;
    if (isVideo) {
      file = MatrixVideoFile(
        bytes: bytes,
        name: fileName,
        width: width,
        height: height,
        duration: durationMs,
      );
    } else {
      file = MatrixImageFile(
        bytes: bytes,
        name: fileName,
        width: width,
        height: height,
      );
    }
    MatrixImageFile? thumbnail;
    if (thumbBytes != null && thumbBytes.isNotEmpty) {
      thumbnail = MatrixImageFile(
        bytes: thumbBytes,
        name: '$fileName.thumb.jpg',
        mimeType: 'image/jpeg',
        width: thumbWidth,
        height: thumbHeight,
      );
    }
    final extraContent = <String, Object?>{};
    if (isVideo && isCircle) {
      extraContent['com.convetchat.circle_video'] = {'duration': durationMs};
    }
    if (caption != null) extraContent['body'] = caption;
    await room.sendFileEvent(
      file,
      thumbnail: thumbnail,
      shrinkImageMaxDimension: isVideo ? null : _sendShrinkMaxDimension,
      extraContent: extraContent.isEmpty ? null : extraContent,
      inReplyTo: _replyTarget(roomId, inReplyToEventId),
    );
  }

  static const _sendShrinkMaxDimension = 1600;

  static const maxUploadBytes = 50 * 1024 * 1024;

  @override
  Future<void> cancelSend({
    required String roomId,
    required String eventId,
  }) async {
    final event = await _timelineEvent(roomId, eventId);
    if (event == null) throw Exception('Сообщение не найдено в timeline');
    if (event.status.isSent) {
      throw Exception('Убрать можно только ещё не отправленное сообщение');
    }
    await event.cancelSend();
  }

  @override
  Future<void> retrySend({
    required String roomId,
    required String eventId,
  }) async {
    final event = await _timelineEvent(roomId, eventId);
    if (event == null) throw Exception('Сообщение не найдено в timeline');
    await event.sendAgain();
  }

  Future<Event?> _timelineEvent(String roomId, String eventId) async {
    final timeline = _timelines[roomId];
    if (timeline == null) return null;
    for (final event in timeline.events) {
      if (event.eventId == eventId) return event;
    }
    try {
      return await timeline.getEventById(eventId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<File> voiceFile(String eventId) async {
    final cacheDir = Directory(
      path_lib.join((await getTemporaryDirectory()).path, 'voice_cache'),
    );
    if (!await cacheDir.exists()) await cacheDir.create(recursive: true);
    final file = File(path_lib.join(cacheDir.path, '${eventId.hashCode}.m4a'));
    if (await file.exists()) return file;
    Event? target;
    for (final timeline in _timelines.values) {
      for (final event in timeline.events) {
        if (event.eventId == eventId) {
          target = event;
          break;
        }
      }
      if (target != null) break;
    }
    final found = target;
    if (found == null) throw Exception('Сообщение не найдено в timeline');

    final matrixFile = await found.downloadAndDecryptAttachment();
    return file.writeAsBytes(matrixFile.bytes);
  }

  final Set<String> _readMarkerBusy = {};

  @override
  Future<void> markAsRead(String roomId) async {
    final room = _room(roomId);
    final timeline = _timelines[roomId];
    if (room == null || timeline == null) return;
    if (!_readMarkerBusy.add(roomId)) return;
    try {
      if (room.markedUnread) await room.markUnread(false);

      await timeline.setReadMarker();
    } catch (_) {
    } finally {
      _readMarkerBusy.remove(roomId);
    }
  }

  @override
  Future<KeyVerification> verifyDirectPartner(String roomId) async {
    final room = _room(roomId);
    final partnerId = room?.directChatMatrixID;
    if (room == null || partnerId == null) {
      throw Exception('Проверка доступна только в личных чатах');
    }
    final devices = _client.userDeviceKeys[partnerId];
    if (devices == null) {
      throw Exception('Устройства собеседника ещё не загружены');
    }
    return devices.startVerification();
  }

  List<ChatMessage> _snapshot(Room room, Timeline timeline) {
    final ownId = _client.userID;
    final showSender = !room.isDirectChat;
    final byId = <String, Event>{};
    for (final event in timeline.events) {
      byId[event.eventId] = event.getDisplayEvent(timeline);
    }
    return timeline.events.where(isChatVisible).map((event) {
      final state = isStateEvent(event);
      final isOwn = !state && event.senderId == ownId;
      final replyToEventId = state
          ? null
          : event.inReplyToEventId(includingFallback: false);
      final replyEvent = replyToEventId == null ? null : byId[replyToEventId];
      final display = event.getDisplayEvent(timeline);
      return ChatMessage(
        id: event.eventId,
        txId: event.transactionId,
        senderId: event.senderId,
        senderName: _senderName(room, event.senderId),
        senderAvatarMxc: room
            .unsafeGetUserFromMemoryOrFallback(event.senderId)
            .avatarUrl
            ?.toString(),
        showSender: showSender,
        body: _body(room, event, display),
        time: event.originServerTs,
        isOwn: isOwn,
        status: state ? null : _status(event, room, isOwn: isOwn),
        replyToEventId: replyToEventId,
        replySenderName: replyEvent == null
            ? null
            : _senderName(room, replyEvent.senderId),
        replyBody: replyEvent == null ? null : eventLabel(replyEvent),
        voice: state ? null : _voice(event),
        media: state ? null : _media(event),
        isState: state,
        isDeleted: event.redacted,
        isEdited: !state && display.eventId != event.eventId,
        isUndecryptable:
            !state &&
            !event.redacted &&
            event.type == EventTypes.Encrypted &&
            event.messageType == MessageTypes.BadEncrypted,
        reactions: state ? const [] : _reactions(event, timeline),
        seenBy: state ? const [] : _seenBy(room, event, ownId: ownId),
      );
    }).toList();
  }

  static List<SeenByUser> _seenBy(
    Room room,
    Event event, {
    required String? ownId,
  }) {
    try {
      final receipts = event.receipts;
      if (receipts.isEmpty) return const [];
      final result = <SeenByUser>[];
      for (final receipt in receipts) {
        final userId = receipt.user.id;
        if (userId == ownId) continue;
        if (userId == event.senderId) continue;
        if (result.any((u) => u.id == userId)) continue;
        result.add(
          SeenByUser(
            id: userId,
            displayName: receipt.user.calcDisplayname(),
            avatarMxc: receipt.user.avatarUrl?.toString(),
          ),
        );
      }
      return result;
    } catch (_) {
      return const [];
    }
  }

  static String _body(Room room, Event event, Event display) {
    if (event.type == EventTypes.RoomPinnedEvents) {
      return _pinLabel(
        content: event.content,
        isOwn: event.senderId == room.client.userID,
        senderName: _senderName(room, event.senderId),
      );
    }
    return eventLabel(display);
  }

  static String _pinLabel({
    required Map<String, Object?> content,
    required bool isOwn,
    required String senderName,
  }) {
    final pinned = content['pinned'];
    final hasPinned = pinned is Iterable && pinned.isNotEmpty;
    if (isOwn) {
      return hasPinned ? 'Вы закрепили сообщение' : 'Вы открепили сообщение';
    }
    return '$senderName ${hasPinned ? 'закрепил сообщение' : 'открепил сообщение'}';
  }

  static VoiceMessage? _voice(Event event) {
    if (event.messageType != MessageTypes.Audio) return null;
    final content = event.content;
    final audio = content.tryGetMap<String, Object?>(
      'org.matrix.msc1767.audio',
    );
    final fileMap = content.tryGetMap<String, Object?>('file');
    final hasVoiceMarker = content.containsKey('org.matrix.msc3245.voice');
    if (audio == null && fileMap == null && !hasVoiceMarker) return null;
    final url =
        content.tryGet<String>('url') ?? fileMap?.tryGet<String>('url') ?? '';
    final info = content.tryGetMap<String, Object?>('info');
    final durationMs =
        audio?.tryGet<int>('duration') ?? info?.tryGet<int>('duration') ?? 0;
    final waveform = audio?.tryGetList<int>('waveform') ?? const <int>[];
    return VoiceMessage(
      eventId: event.eventId,
      mxc: url,
      durationMs: durationMs,
      waveform: waveform,
      mimeType:
          content.tryGet<String>('mimetype') ??
          info?.tryGet<String>('mimetype') ??
          'audio/x-m4a',
    );
  }

  static MediaAttachment? _media(Event event) {
    final type = event.messageType;
    final isImage = type == MessageTypes.Image;
    final isVideo = type == MessageTypes.Video;
    if (!isImage && !isVideo) return null;
    if (!event.hasAttachment &&
        (event.status.isSent ||
            (!event.status.isSending && !event.status.isError))) {
      return null;
    }
    final info = event.content.tryGetMap<String, Object?>('info');
    final filename = event.content.tryGet<String>('filename');
    final body = event.calcUnlocalizedBody(
      hideReply: true,
      plaintextBody: true,
    );
    final caption =
        filename != null &&
            filename != body &&
            event.content.tryGet<String>('body')?.isNotEmpty == true
        ? body
        : null;
    return MediaAttachment(
      kind: isVideo ? .video : .image,
      width: info?.tryGet<int>('w'),
      height: info?.tryGet<int>('h'),
      durationMs: info?.tryGet<int>('duration'),
      mimeType:
          event.content.tryGet<String>('mimetype') ??
          info?.tryGet<String>('mimetype'),
      size: info?.tryGet<int>('size'),
      fileName: filename ?? event.content.tryGet<String>('body'),
      caption: caption,
      isCircle:
          isVideo && event.content.containsKey('com.convetchat.circle_video'),
      hasThumb:
          info?.containsKey('thumbnail_url') == true ||
          info?.containsKey('thumbnail_file') == true,
    );
  }

  @override
  Future<Uint8List> mediaBytes({
    required String roomId,
    required String eventId,
    required bool thumb,
  }) async {
    final timeline = _timelines[roomId];
    Event? target;
    if (timeline != null) {
      for (final event in timeline.events) {
        if (event.eventId == eventId) {
          target = event;
          break;
        }
      }
    }
    final found = target ?? await _findEvent(roomId, eventId);
    if (found == null) throw Exception('Сообщение не найдено в timeline');
    return (await found.downloadAndDecryptAttachment(getThumbnail: thumb))
        .bytes;
  }

  Future<Event?> _findEvent(String roomId, String eventId) async {
    final timeline = _timelines[roomId];
    if (timeline == null) return null;
    try {
      return await timeline.getEventById(eventId);
    } catch (_) {
      return null;
    }
  }

  static List<MessageReaction> _reactions(Event event, Timeline timeline) {
    final ownId = event.room.client.userID;
    final counts = <String, int>{};
    final reacted = <String>{};
    for (final e in event.aggregatedEvents(
      timeline,
      RelationshipTypes.reaction,
    )) {
      final key = e.content
          .tryGetMap<String, Object?>('m.relates_to')
          ?.tryGet<String>('key');
      if (key == null || key.isEmpty) continue;
      if (e.redacted) continue;
      counts[key] = (counts[key] ?? 0) + 1;
      if (e.senderId == ownId) reacted.add(key);
    }
    if (counts.isEmpty) return const [];
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return [
      for (final e in entries)
        MessageReaction(
          key: e.key,
          count: e.value,
          reacted: reacted.contains(e.key),
        ),
    ];
  }

  @override
  Future<void> toggleReaction({
    required String roomId,
    required String eventId,
    required String emoji,
  }) async {
    final room = _room(roomId);
    if (room == null) throw Exception('Комната не найдена');
    final timeline = _timelines[roomId];
    final ownId = _client.userID;
    Event? target;
    if (timeline != null) {
      for (final event in timeline.events) {
        if (event.eventId == eventId) {
          target = event;
          break;
        }
      }
    }
    target ??= await _findEvent(roomId, eventId);
    if (target != null && timeline != null) {
      Event? existing;
      for (final e in target.aggregatedEvents(
        timeline,
        RelationshipTypes.reaction,
      )) {
        if (e.redacted) continue;
        if (e.senderId != ownId) continue;
        final key = e.content
            .tryGetMap<String, Object?>('m.relates_to')
            ?.tryGet<String>('key');
        if (key == emoji) {
          existing = e;
          break;
        }
      }
      if (existing != null) {
        await existing.redactEvent();
        return;
      }
    }
    await room.sendReaction(eventId, emoji);
  }

  static MessageStatus? _status(Event event, Room room, {required bool isOwn}) {
    if (!isOwn) return null;
    if (event.status == .error) return .failed;
    if (event.status == .sending) return .sending;
    final readByOthers = room.receiptState.global.otherUsers.values.any(
      (receipt) => receipt.eventId == event.eventId,
    );
    return readByOthers ? MessageStatus.read : MessageStatus.sent;
  }

  static bool _hasUndecrypted(Timeline timeline) {
    return timeline.events.any(
      (event) =>
          event.type == EventTypes.Encrypted &&
          event.messageType == MessageTypes.BadEncrypted,
    );
  }

  static void _requestKeysIfNeeded(String roomId, Timeline timeline) {
    final bad = timeline.events
        .where(
          (event) =>
              event.type == EventTypes.Encrypted &&
              event.messageType == MessageTypes.BadEncrypted &&
              event.content['can_request_session'] == true,
        )
        .toList();
    if (bad.isNotEmpty) {
      timeline.requestKeys(onlineKeyBackupOnly: false);
    }
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
  Future<void> redactMessage({
    required String roomId,
    required String eventId,
  }) async {
    final room = _room(roomId);
    if (room == null) throw Exception('Комната не найдена');
    await room.redactEvent(eventId);
  }

  @override
  Stream<List<String>> watchPinnedEvents(String roomId) async* {
    List<String> snapshot() => _room(roomId)?.pinnedEventIds ?? [];
    yield snapshot();
    await for (final _ in _client.onSync.stream) {
      yield snapshot();
    }
  }

  @override
  Future<void> pinMessage({
    required String roomId,
    required String eventId,
  }) async {
    final room = _room(roomId);
    if (room == null) throw Exception('Комната не найдена');
    await room.setPinnedEvents([eventId]);
  }

  @override
  Future<void> unpinMessage({required String roomId}) async {
    final room = _room(roomId);
    if (room == null) throw Exception('Комната не найдена');
    await room.setPinnedEvents([]);
  }

  @override
  Future<List<({String id, String name})>> forwardTargets(
    String exceptRoomId,
  ) async {
    final targets = <({String id, String name})>[];
    final ownId = _client.userID;
    for (final r in _client.rooms.toList(growable: false)) {
      if (r.id == exceptRoomId) continue;
      if (r.membership != Membership.join) continue;
      if ((r.id == ownId) && r.directChatMatrixID == ownId) continue;
      targets.add((id: r.id, name: r.getLocalizedDisplayname()));
    }
    targets.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return targets;
  }

  @override
  Future<void> forwardMessage({
    required String sourceRoomId,
    required String targetRoomId,
    required String eventId,
  }) async {
    final source = _room(sourceRoomId);
    final target = _room(targetRoomId);
    if (source == null || target == null) {
      throw Exception('Комната не найдена');
    }
    final sourceTimeline = _timelines[sourceRoomId];
    if (sourceTimeline == null) {
      throw Exception('Источник пересылки недоступен');
    }
    final event = await sourceTimeline.getEventById(eventId);
    if (event == null || isStateEvent(event)) {
      throw Exception('Сообщение не найдено или его нельзя переслать');
    }
    final text = event
        .calcLocalizedBodyFallback(
          ruMatrixLocalizations,
          hideReply: true,
          hideEdit: true,
          plaintextBody: true,
          removeMarkdown: true,
        )
        .trim();
    if (text.isEmpty) {
      throw Exception('Пересылать можно только текстовые сообщения');
    }
    await target.sendTextEvent(text);
  }
}
