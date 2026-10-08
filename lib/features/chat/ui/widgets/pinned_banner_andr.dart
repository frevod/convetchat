import 'package:convetchat/features/chat/domain/entities/chat_message.dart';
import 'package:convetchat/features/chat/ui/cubit/chat_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_3_expressive/components/icon_buttons/m3e_icon_buttons.dart';
import 'package:material_ui/material_ui.dart';

String pinnedPreviewText(ChatMessage message) {
  if (message.isDeleted) return 'Сообщение удалено';
  if (message.isUndecryptable) return 'Не удалось расшифровать';
  final body = message.body.trim();
  if (body.isNotEmpty) return body;
  if (message.voice != null) return 'Голосовое сообщение';
  final media = message.media;
  if (media != null) {
    return switch (media.kind) {
      .video => 'Видео',
      .image => 'Изображение',
      .file => media.fileName ?? 'Файл',
    };
  }
  return 'Сообщение';
}

class const PinnedBannerAndr({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ChatCubit>();
    final pinnedId = context.select(
      (ChatCubit c) =>
          c.state.pinnedEventIds.isEmpty ? null : c.state.pinnedEventIds.first,
    );
    if (pinnedId == null) return const SizedBox.shrink();
    final message = context.select((ChatCubit c) {
      for (final m in c.state.messages) {
        if (m.id == pinnedId) return m;
      }
      return null;
    });
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      behavior: .opaque,
      onTap: () => cubit.jumpToMessage(pinnedId),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          border: Border(
            bottom: BorderSide(
              color: scheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            Icon(Icons.push_pin_rounded, size: 20, color: scheme.primary),
            Container(
              width: 3,
              height: 36,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: scheme.primary,
                borderRadius: .circular(2),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: .start,
                mainAxisSize: .min,
                children: [
                  Text(
                    'Закреплённое сообщение',
                    style: textTheme.labelMedium?.copyWith(
                      color: scheme.primary,
                    ),
                    maxLines: 1,
                    overflow: .ellipsis,
                  ),
                  Text(
                    message == null
                        ? 'Нажмите, чтобы перейти'
                        : '${message.senderName}: ${pinnedPreviewText(message)}',
                    style: textTheme.bodySmall,
                    maxLines: 1,
                    overflow: .ellipsis,
                  ),
                ],
              ),
            ),
            M3EIconButton(
              icon: const Icon(Icons.close_rounded, size: 20),
              tooltip: 'Открепить',
              variant: .standard,
              onPressed: () => cubit.unpinMessage(),
            ),
          ],
        ),
      ),
    );
  }
}
