import 'package:convetchat/features/chat/domain/entities/chat_message.dart';
import 'package:convetchat/features/chat/ui/widgets/reply_widget.dart';
import 'package:flutter/widgets.dart';

class const ReplyPreviewAnimation({
  super.key,
  required final ChatMessage? reply,
  required final VoidCallback onCancel,
  required final void Function(ChatMessage message) onTapMessage,
  final EdgeInsetsGeometry? contentPadding,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final current = reply;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      reverseDuration: const Duration(milliseconds: 200),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (currentChild, previousChildren) => Stack(
        alignment: Alignment.bottomCenter,
        children: [?currentChild, ...previousChildren],
      ),
      transitionBuilder: (child, animation) {
        final slide =
            Tween<Offset>(
              begin: const Offset(0, 0.35),
              end: Offset.zero,
            ).animate(animation);
        return ClipRect(
          child: SizeTransition(
            sizeFactor: animation,
            alignment: Alignment.bottomCenter,
            child: FadeTransition(
              opacity: animation,
              child: SlideTransition(position: slide, child: child),
            ),
          ),
        );
      },
      child: current != null
          ? Padding(
              key: ValueKey('reply-${current.id}'),
              padding: contentPadding ?? EdgeInsets.zero,
              child: ReplyWidget(
                reply: current,
                onCancel: onCancel,
                onTap: () => onTapMessage(current),
              ),
            )
          : const SizedBox.shrink(key: ValueKey('reply-empty')),
    );
  }
}
