import 'package:convetchat/features/chat/domain/entities/media_attachment.dart';
import 'package:convetchat/features/chat/domain/entities/voice_message.dart';
import 'package:equatable/equatable.dart';

enum MessageStatus() {
  sending,
  sent,
  read,
  failed,
}

class const MessageReaction({
  required final String key,
  required final int count,
  required final bool reacted,
}) extends Equatable {
  @override
  List<Object?> get props => [key, count, reacted];
}

class const SeenByUser({
  required final String id,
  required final String displayName,
  required final String? avatarMxc,
}) extends Equatable {
  @override
  List<Object?> get props => [id, displayName, avatarMxc];
}

class const ChatMessage({
  required final String id,
  required final String? txId,
  required final String senderId,
  required final String senderName,
  required final String? senderAvatarMxc,
  required final bool showSender,
  required final String body,
  final String? bodyHtml,
  final double? bigEmojiSize,
  required final DateTime time,
  required final bool isOwn,
  required final MessageStatus? status,
  required final String? replyToEventId,
  required final String? replySenderName,
  required final String? replyBody,

  required final VoiceMessage? voice,
  required final MediaAttachment? media,
  final bool isState = false,

  final bool isDeleted = false,

  final bool isUndecryptable = false,
  final bool isEdited = false,
  final List<MessageReaction> reactions = const [],
  final List<SeenByUser> seenBy = const [],
}) extends Equatable {
  bool get isBody =>
      !isDeleted && !isUndecryptable && media == null && voice == null;

  bool get hasReactions => reactions.isNotEmpty;

  bool get canReact =>
      !isState && !isDeleted && !isUndecryptable && status != .sending;

  @override
  List<Object?> get props => [
    id,
    txId,
    senderId,
    senderName,
    senderAvatarMxc,
    showSender,
    body,
    bodyHtml,
    bigEmojiSize,
    time,
    isOwn,
    status,
    replyToEventId,
    replySenderName,
    replyBody,
    voice,
    media,
    isState,
    isDeleted,
    isUndecryptable,
    isEdited,
    reactions,
    seenBy,
  ];
}
