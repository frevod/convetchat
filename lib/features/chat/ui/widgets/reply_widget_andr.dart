import 'package:convetchat/features/chat/domain/entities/chat_message.dart';
import 'package:material_3_expressive/components/icon_buttons/m3e_icon_buttons.dart';
import 'package:material_ui/material_ui.dart';

class const ReplyWidgetAndr({
  super.key,
  required final ChatMessage reply,
  required final VoidCallback onCancel,
  required final VoidCallback onTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        width: .infinity,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          borderRadius: .circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
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
                        style: TextStyle(
                          fontWeight: .w600,
                          color: scheme.primary,
                        ),
                      ),
                      Text(reply.body, overflow: .ellipsis, maxLines: 1),
                    ],
                  ),
                ),
              ),
              M3EIconButton(
                variant: .standard,
                icon: const Icon(Icons.close_rounded),
                tooltip: 'Отменить ответ',
                onPressed: onCancel,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
