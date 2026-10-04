import 'package:convetchat/core/utils/message_format.dart';
import 'package:convetchat/core/widgets/mxc_avatar.dart';
import 'package:convetchat/features/chat/domain/entities/chat_message.dart';
import 'package:convetchat/features/chat/ui/cubit/chat_cubit.dart';
import 'package:convetchat/features/chat/ui/widgets/message_deleted_label.dart';
import 'package:convetchat/features/chat/ui/widgets/message_reactions.dart';
import 'package:convetchat/features/chat/ui/widgets/media_message_andr.dart';
import 'package:convetchat/features/chat/ui/widgets/message_reply_quote.dart';
import 'package:convetchat/features/chat/ui/widgets/message_status_icon.dart';
import 'package:convetchat/features/chat/ui/widgets/reply_swipe_indicator_andr.dart';
import 'package:convetchat/features/chat/ui/widgets/seen_by_avatars.dart';
import 'package:convetchat/features/chat/ui/widgets/swipe_to_reply.dart';
import 'package:convetchat/features/chat/ui/widgets/voice_player.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

class const MessageBubbleAndr({
  super.key,
  required final ChatMessage message,
  final bool highlighted = false,
  final GlobalKey? anchorKey,
  final bool aboveSameSender = false,
  final bool belowSameSender = false,

  final bool previewOnly = false,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isOwn = message.isOwn;

    final showSender = message.showSender && !isOwn && !aboveSameSender;
    final baseColor = isOwn ? scheme.primary : scheme.surfaceContainerHighest;

    final deleted = message.isDeleted;
    final undecryptable = message.isUndecryptable;
    final placeholder = deleted || undecryptable;
    final hasMedia = !placeholder && message.media != null;
    final isCircle = !placeholder && message.media?.isCircle == true;

    if (isCircle) {
      return _withReactions(
        context,
        showSender: showSender,
        child: _swipeable(
          context,
          Align(
            alignment: isOwn ? .centerRight : .centerLeft,
            child: Container(
              key: anchorKey,
              margin: EdgeInsets.only(
                left: 12,
                right: 12,
                top: aboveSameSender ? 1 : 4,
                bottom: belowSameSender ? 1 : 4,
              ),
              child: Column(
                crossAxisAlignment: isOwn ? .end : .start,
                mainAxisSize: .min,
                children: [
                  if (showSender)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        message.senderName,
                        maxLines: 1,
                        overflow: .ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: .w600,
                          color: scheme.primary,
                        ),
                      ),
                    ),
                  if (message.replyToEventId != null)
                    MessageReplyQuote(
                      senderName: message.replySenderName,
                      body: message.replyBody,
                      isOwn: isOwn,
                      onTap: () => context.read<ChatCubit>().jumpToMessage(
                        message.replyToEventId!,
                      ),
                    ),
                  MediaMessageAndr(
                    message: message,
                    previewOnly: previewOnly,
                    highlighted: highlighted,
                  ),
                  _CircleMeta(message: message),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final placeholderColor = isOwn ? scheme.onSurface : scheme.onSurfaceVariant;

    final bubbleColor = placeholder
        ? scheme.surfaceContainer
        : highlighted
        ? Color.alphaBlend(const Color(0x40000000), baseColor)
        : baseColor;

    const hardCorner = Radius.circular(3);
    final roundedCorner = Radius.circular(18);
    final borderRadius = BorderRadius.only(
      topLeft: !isOwn ? hardCorner : roundedCorner,
      topRight: isOwn && aboveSameSender ? hardCorner : roundedCorner,
      bottomLeft: !isOwn && belowSameSender ? hardCorner : roundedCorner,
      bottomRight: isOwn ? hardCorner : roundedCorner,
    );

    final bubble = ConstrainedBox(
      key: anchorKey,
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.75,
      ),
      child: Container(
        margin: EdgeInsets.only(
          left: 12,
          right: 12,
          top: aboveSameSender ? 1 : 4,
          bottom: belowSameSender ? 1 : 4,
        ),
        padding: hasMedia
            ? const EdgeInsets.all(4)
            : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: borderRadius,
          border: highlighted
              ? Border.all(
                  color: isOwn ? scheme.onPrimary : scheme.primary,
                  width: 2.5,
                )
              : null,
        ),
        child: Column(
          crossAxisAlignment: isOwn ? .end : .start,
          mainAxisSize: .min,
          children: [
            if (showSender)
              Text(
                message.senderName,
                maxLines: 1,
                overflow: .ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: .w600,
                  color: scheme.primary,
                ),
              ),
            if (!placeholder && message.replyToEventId != null)
              MessageReplyQuote(
                senderName: message.replySenderName,
                body: message.replyBody,
                isOwn: isOwn,
                onTap: () => context.read<ChatCubit>().jumpToMessage(
                  message.replyToEventId!,
                ),
              ),
            if (deleted)
              MessageDeletedLabel(color: placeholderColor)
            else if (undecryptable)
              MessageDeletedLabel(
                color: placeholderColor,
                text: 'Не удалось расшифровать',
                icon: Icons.lock_outline,
              )
            else if (hasMedia)
              MediaMessageAndr(message: message, previewOnly: previewOnly)
            else if (message.voice != null)
              DefaultTextStyle(
                style: TextStyle(
                  color: isOwn ? scheme.onPrimary : scheme.onSurfaceVariant,
                ),
                child: VoicePlayer(
                  voice: message.voice!,
                  accent: isOwn ? scheme.onPrimary : scheme.primary,
                  track: (isOwn ? scheme.onPrimary : scheme.primary).withValues(
                    alpha: 0.3,
                  ),
                  playIcon: Icons.play_arrow_rounded,
                  pauseIcon: Icons.pause_rounded,
                  iconColor: isOwn ? scheme.primary : scheme.primaryContainer,
                  buttonColor: isOwn ? scheme.primaryContainer : scheme.primary,
                  loadingColor: isOwn
                      ? scheme.primary
                      : scheme.primaryContainer,
                ),
              )
            else
              Text(
                message.body,
                style: TextStyle(
                  fontSize: 15,
                  color: isOwn ? scheme.onPrimary : scheme.onSurfaceVariant,
                ),
              ),
            if (!hasMedia) ...[
              const SizedBox(height: 2),
              Row(
                mainAxisSize: .min,
                children: [
                  if (message.isEdited) ...[
                    Text(
                      'изменено',
                      style: TextStyle(
                        fontSize: 11,
                        fontStyle: .italic,
                        color: (deleted || undecryptable)
                            ? placeholderColor
                            : (isOwn
                                      ? scheme.onPrimary
                                      : scheme.onSurfaceVariant)
                                  .withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    messageClockText(message.time),
                    style: TextStyle(
                      fontSize: 11,
                      color: (deleted || undecryptable)
                          ? placeholderColor
                          : (isOwn ? scheme.onPrimary : scheme.onSurfaceVariant)
                                .withValues(alpha: 0.7),
                    ),
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    alignment: .centerLeft,
                    child: Row(
                      mainAxisSize: .min,
                      children: [
                        if (message.status == .sending ||
                            message.status == .failed) ...[
                          const SizedBox(width: 4),
                          if (isOwn && message.status == .failed)
                            GestureDetector(
                              onTap: () => context
                                  .read<ChatCubit>()
                                  .retrySendMessage(message),
                              child: MessageStatusIcon(status: message.status),
                            )
                          else
                            MessageStatusIcon(status: message.status),
                          if (isOwn && message.status == .failed)
                            GestureDetector(
                              onTap: () => context
                                  .read<ChatCubit>()
                                  .cancelSendMessage(message),
                              child: Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 14,
                                  color: scheme.onPrimary.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );

    if (!showSender) {
      final aligned = Align(
        alignment: isOwn ? .centerRight : .centerLeft,
        child: bubble,
      );
      if (!isOwn && message.showSender) {
        return _withReactions(
          context,
          showSender: false,
          child: _swipeable(
            context,
            Padding(padding: const EdgeInsets.only(left: 40), child: aligned),
          ),
        );
      }
      return _withReactions(
        context,
        showSender: false,
        child: _swipeable(context, aligned),
      );
    }
    return _withReactions(
      context,
      showSender: true,
      child: _swipeable(
        context,
        Row(
          crossAxisAlignment: .start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 10),
              child: MxcAvatar(
                mxc: message.senderAvatarMxc,
                fallback: avatarInitial(message.senderName),
                size: 32,
                context: context,
              ),
            ),
            Flexible(child: bubble),
          ],
        ),
      ),
    );
  }

  Widget _withReactions(
    BuildContext context, {
    required bool showSender,
    required Widget child,
  }) {
    final hasReactions = !previewOnly && message.reactions.isNotEmpty;
    final hasSeen = !previewOnly && message.seenBy.isNotEmpty;
    if (!hasReactions && !hasSeen) return child;
    final indent = showSender && !message.isOwn ? 40.0 : 0.0;
    return Column(
      mainAxisSize: .min,
      crossAxisAlignment: message.isOwn ? .end : .start,
      children: [
        child,
        if (hasReactions)
          MessageReactions(message: message, indent: indent),
        if (hasSeen)
          SeenByAvatars(
            seenBy: message.seenBy,
            isOwn: message.isOwn,
            indent: indent,
          ),
      ],
    );
  }

  Widget _swipeable(BuildContext context, Widget content) {
    if (previewOnly) return content;
    return SwipeToReply(
      onReply: () => context.read<ChatCubit>().setReply(message),
      actionBuilder: (actionContext, progress) =>
          ReplySwipeIndicatorAndr(progress: progress),
      child: content,
    );
  }
}

class const _CircleMeta({required final ChatMessage message})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final status = message.status;
    final showStatus = status == .sending || status == .failed;
    final timeColor = scheme.onSurfaceVariant.withValues(alpha: 0.7);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisSize: .min,
        children: [
          Text(
            messageClockText(message.time),
            style: TextStyle(fontSize: 11, color: timeColor),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            alignment: .centerLeft,
            child: Row(
              mainAxisSize: .min,
              children: [
                if (showStatus) ...[
                  const SizedBox(width: 4),
                  if (message.isOwn && status == .failed)
                    GestureDetector(
                      onTap: () =>
                          context.read<ChatCubit>().retrySendMessage(message),
                      child: MessageStatusIcon(status: status),
                    )
                  else
                    MessageStatusIcon(status: status),
                  if (message.isOwn && status == .failed)
                    GestureDetector(
                      onTap: () =>
                          context.read<ChatCubit>().cancelSendMessage(message),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Icon(
                          Icons.close_rounded,
                          size: 14,
                          color: timeColor,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
