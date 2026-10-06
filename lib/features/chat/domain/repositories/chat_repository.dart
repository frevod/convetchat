import 'dart:io';
import 'dart:typed_data';

import 'package:convetchat/features/chat/domain/entities/chat_message.dart';
import 'package:convetchat/features/chat/domain/entities/chat_send_restriction.dart';
import 'package:convetchat/features/chat/domain/entities/room_info.dart';
import 'package:matrix/encryption.dart';

abstract class ChatRepository() {
  String roomName(String roomId);

  String? roomAvatar(String roomId);

  Stream<List<ChatMessage>> watchMessages(String roomId);

  Future<void> loadMore(String roomId);

  String? directChatPartner(String roomId);

  Stream<RoomInfo> watchRoomInfo(String roomId);

  Future<void> leaveRoom(String roomId);

  Stream<({bool online, DateTime? lastActive})> watchPartnerPresence(
    String roomId,
  );

  Stream<List<({String id, String name})>> watchTypingUsers(String roomId);

  Stream<ChatSendRestriction> watchSendRestriction(String roomId);

  Future<void> setTyping(String roomId, bool isTyping);

  Future<void> sendText({
    required String roomId,
    required String text,
    String? inReplyToEventId,
  });

  Future<void> editText({
    required String roomId,
    required String eventId,
    required String text,
  });

  Future<void> markAsRead(String roomId);

  Future<void> sendVoice({
    required String roomId,
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
    required int durationMs,
    required List<int> waveform,
    String? inReplyToEventId,
  });

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
  });

  Future<void> cancelSend({required String roomId, required String eventId});

  Future<void> retrySend({required String roomId, required String eventId});

  Future<File> voiceFile(String eventId);

  Future<bool> isMediaCached({
    required String roomId,
    required String eventId,
    required bool thumb,
  });

  Future<bool> isVoiceCached(String eventId);

  Future<Uint8List> mediaBytes({
    required String roomId,
    required String eventId,
    required bool thumb,
  });

  Future<KeyVerification> verifyDirectPartner(String roomId);

  Future<void> redactMessage({required String roomId, required String eventId});

  Future<void> hideEvent({required String roomId, required String eventId});

  Stream<List<String>> watchPinnedEvents(String roomId);

  Future<void> pinMessage({required String roomId, required String eventId});

  Future<void> unpinMessage({required String roomId});

  Future<List<({String id, String name})>> forwardTargets(String exceptRoomId);

  Future<void> forwardMessage({
    required String sourceRoomId,
    required String targetRoomId,
    required String eventId,
  });

  Future<void> toggleReaction({
    required String roomId,
    required String eventId,
    required String emoji,
  });

  Future<bool> isMarkdownEnabled();

  Future<void> setMarkdownEnabled(bool enabled);

  Future<bool> isBigEmojisEnabled();

  Future<void> setBigEmojisEnabled(bool enabled);

  Future<bool> isHideDeletedEnabled();

  Future<void> setHideDeletedEnabled(bool enabled);

  Future<bool> isHideUnknownFormatsEnabled();

  Future<void> setHideUnknownFormatsEnabled(bool enabled);

  Future<bool> isHideUndecryptableEnabled();

  Future<void> setHideUndecryptableEnabled(bool enabled);

  Future<bool> isAutoplayEnabled();

  Future<void> setAutoplayEnabled(bool enabled);

  Future<bool> isVoiceAutoplayEnabled();

  Future<void> setVoiceAutoplayEnabled(bool enabled);

  Future<bool> isVideoAutoplayEnabled();

  Future<void> setVideoAutoplayEnabled(bool enabled);

  Future<bool> isSendOnEnterEnabled();

  Future<void> setSendOnEnterEnabled(bool enabled);

  Future<bool> isSwipeToReplyEnabled();

  Future<void> setSwipeToReplyEnabled(bool enabled);

  Future<bool> isQuickReactionEnabled();

  Future<void> setQuickReactionEnabled(bool enabled);

  Future<String> getQuickReactionEmoji();

  Future<void> setQuickReactionEmoji(String emoji);
}
