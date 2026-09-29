import 'package:convetchat/features/chat/domain/entities/media_attachment.dart';
import 'package:convetchat/features/chat/domain/entities/voice_message.dart';
import 'package:equatable/equatable.dart';

enum MessageStatus() {
  sending,
  sent,
  read,
  failed,
}

class const ChatMessage({
  required final String id,
  required final String senderId,
  required final String senderName,
  required final String? senderAvatarMxc,
  required final bool showSender,
  required final String body,
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
}) extends Equatable {
  @override
  List<Object?> get props => [
    id,
    senderId,
    senderName,
    senderAvatarMxc,
    showSender,
    body,
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
  ];
}
