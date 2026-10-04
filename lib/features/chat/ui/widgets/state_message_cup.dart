import 'package:convetchat/features/chat/domain/entities/chat_message.dart';
import 'package:cupertino_ui/cupertino_ui.dart';

class const StateMessageCup({
  super.key,
  required final ChatMessage message,
  final bool isCollapsed = false,
  final bool expanded = false,
  final VoidCallback? onExpand,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (isCollapsed) return const SizedBox.shrink();
    final pillBg = CupertinoColors.systemGrey
        .resolveFrom(context)
        .withValues(alpha: 0.25);
    final grey = CupertinoColors.systemGrey.resolveFrom(context);
    final blue = CupertinoColors.activeBlue.resolveFrom(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 4),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: pillBg, borderRadius: .circular(12)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message.body,
                textAlign: .center,
                style: TextStyle(fontSize: 12, color: grey),
              ),
              if (onExpand != null) ...[
                const SizedBox(height: 2),
                GestureDetector(
                  onTap: onExpand,
                  child: Text(
                    expanded ? 'Скрыть' : 'Ещё события',
                    style: TextStyle(
                      fontSize: 11,
                      color: blue,
                      decoration: TextDecoration.underline,
                      decorationColor: blue,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
