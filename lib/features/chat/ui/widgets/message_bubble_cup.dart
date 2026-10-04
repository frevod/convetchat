import 'package:convetchat/core/utils/message_format.dart';
import 'package:convetchat/core/widgets/mxc_avatar.dart';
import 'package:convetchat/features/chat/domain/entities/chat_message.dart';
import 'package:convetchat/features/chat/ui/cubit/chat_cubit.dart';
import 'package:convetchat/features/chat/ui/widgets/media_message.dart';
import 'package:convetchat/features/chat/ui/widgets/message_deleted_label.dart';
import 'package:convetchat/features/chat/ui/widgets/message_reply_quote.dart';
import 'package:convetchat/features/chat/ui/widgets/message_status_icon.dart';
import 'package:convetchat/features/chat/ui/widgets/swipe_to_reply.dart';
import 'package:convetchat/features/chat/ui/widgets/voice_player.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class const MessageBubbleCup({
  super.key,
  required final ChatMessage message,
  final bool highlighted = false,
  final GlobalKey? anchorKey,
  final bool aboveSameSender = false,
  final bool belowSameSender = false,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isOwn = message.isOwn;

    final showSender = message.showSender && !isOwn && !aboveSameSender;
    final blue = CupertinoColors.activeBlue.resolveFrom(context);

    const white = CupertinoColors.white;
    final baseColor = isOwn
        ? blue
        : CupertinoColors.systemFill.resolveFrom(context);

    final contentColor = isOwn
        ? white
        : CupertinoColors.label.resolveFrom(context);
    final timeColor = isOwn
        ? white.withValues(alpha: 0.85)
        : CupertinoColors.secondaryLabel.resolveFrom(context);

    final deleted = message.isDeleted;
    final undecryptable = message.isUndecryptable;
    final placeholder = deleted || undecryptable;
    final hasMedia = !placeholder && message.media != null;

    final placeholderColor = isOwn
        ? white
        : CupertinoColors.secondaryLabel.resolveFrom(context);

    final bubbleColor = placeholder
        ? CupertinoColors.tertiarySystemFill.resolveFrom(context)
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
              ? Border.all(color: isOwn ? white : blue, width: 2.5)
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
                style: TextStyle(fontSize: 12, fontWeight: .w600, color: blue),
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
                text: 'Не удалось расшифровать сообщение',
                icon: CupertinoIcons.lock,
              )
            else if (hasMedia)
              MediaMessage(message: message)
            else if (message.voice != null)
              VoicePlayer(
                voice: message.voice!,
                accent: isOwn ? white : contentColor,
                track: contentColor.withValues(alpha: 0.3),
                playIcon: CupertinoIcons.play_fill,
                pauseIcon: CupertinoIcons.pause_fill,
                iconColor: contentColor,
                buttonColor: isOwn
                    ? white.withValues(alpha: 0.25)
                    : CupertinoColors.tertiarySystemFill.resolveFrom(context),
                loadingColor: contentColor,
              )
            else
              Text(
                message.body,
                style: TextStyle(fontSize: 15, color: contentColor),
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
                        color: placeholder
                            ? placeholderColor.withValues(alpha: 0.85)
                            : timeColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    messageClockText(message.time),
                    style: TextStyle(
                      fontSize: 11,
                      color: placeholder
                          ? placeholderColor.withValues(alpha: 0.85)
                          : timeColor,
                    ),
                  ),
                  if (message.status != null) ...[
                    const SizedBox(width: 4),
                    if (isOwn && message.status == .failed)
                      GestureDetector(
                        onTap: () =>
                            context.read<ChatCubit>().retrySendMessage(message),
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
                            CupertinoIcons.xmark,
                            size: 13,
                            color: timeColor,
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );

    if (!showSender) {
      final aligned = Align(
        key: anchorKey,
        alignment: isOwn ? .centerRight : .centerLeft,
        child: bubble,
      );
      if (!isOwn && message.showSender) {
        return _swipeable(
          context,
          Padding(padding: const EdgeInsets.only(left: 40), child: aligned),
        );
      }
      return _swipeable(context, aligned);
    }
    return _swipeable(
      context,
      Row(
        key: anchorKey,
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
    );
  }

  Widget _swipeable(BuildContext context, Widget content) {
    final blue = CupertinoColors.activeBlue.resolveFrom(context);
    return SwipeToReply(
      onReply: () => context.read<ChatCubit>().setReply(message),
      actionBuilder: (_, progress) => Opacity(
        opacity: progress,
        child: Icon(CupertinoIcons.reply, size: 22, color: blue),
      ),
      child: content,
    );
  }
}
