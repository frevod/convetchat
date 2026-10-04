import 'package:convetchat/features/chat/domain/entities/chat_message.dart';
import 'package:cupertino_ui/cupertino_ui.dart';

class const ReplyWidgetCup({
  super.key,
  required final ChatMessage reply,
  required final VoidCallback onCancel,
  required final VoidCallback onTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final bg = CupertinoColors.systemGrey6.resolveFrom(context);
    final blue = CupertinoColors.activeBlue.resolveFrom(context);
    final grey = CupertinoColors.systemGrey.resolveFrom(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                behavior: .opaque,
                onTap: onTap,
                child: Column(
                  crossAxisAlignment: .start,
                  mainAxisSize: .min,
                  children: [
                    Text(
                      reply.senderName,
                      maxLines: 1,
                      overflow: .ellipsis,
                      style: TextStyle(fontWeight: .w600, color: blue),
                    ),
                    Text(reply.body, overflow: .ellipsis, maxLines: 1),
                  ],
                ),
              ),
            ),
            CupertinoButton(
              onPressed: onCancel,
              padding: EdgeInsets.zero,
              minimumSize: const Size(32, 32),
              child: Icon(CupertinoIcons.xmark, size: 18, color: grey),
            ),
          ],
        ),
      ),
    );
  }
}
