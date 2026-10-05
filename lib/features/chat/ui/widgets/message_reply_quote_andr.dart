import 'package:material_ui/material_ui.dart';

class const MessageReplyQuoteAndr({
  super.key,
  required final String? senderName,
  required final String? body,
  required final bool isOwn,
  required final VoidCallback onTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      behavior: .opaque,
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isOwn ? scheme.primaryContainer : scheme.surfaceContainer,
          borderRadius: .circular(10),
        ),
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
                color: isOwn ? scheme.onPrimaryContainer : scheme.primary,
              ),
            ),
            Text(
              body ?? '…',
              maxLines: 2,
              overflow: .ellipsis,
              style: TextStyle(
                fontSize: 13,
                color:
                    (isOwn
                            ? scheme.onPrimaryContainer
                            : scheme.onSurfaceVariant)
                        .withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
