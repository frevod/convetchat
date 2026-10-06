import 'package:convetchat/core/widgets/interaction_guard.dart';
import 'package:cupertino_ui/cupertino_ui.dart';

class const MessageReplyQuoteCup({
  super.key,
  required final String? senderName,
  required final String? body,
  required final bool isOwn,
  required final VoidCallback onTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final quoteBg =
        (isOwn ? CupertinoColors.systemFill : CupertinoColors.systemGrey4)
            .resolveFrom(context);

    final foreground = isOwn
        ? CupertinoColors.white
        : CupertinoColors.label.resolveFrom(context);
    return GestureDetector(
      behavior: .opaque,
      onTap: () {
        InteractionGuard.mark();
        onTap();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: quoteBg, borderRadius: .circular(10)),
        child: Column(
          crossAxisAlignment: .start,
          mainAxisSize: .min,
          children: [
            Text(
              senderName ?? '…',
              maxLines: 1,
              overflow: .ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: .w600,
                color: foreground,
              ),
            ),
            Text(
              body ?? '…',
              maxLines: 2,
              overflow: .ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: foreground.withValues(alpha: isOwn ? 0.92 : 1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
