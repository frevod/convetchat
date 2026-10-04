import 'package:convetchat/features/chat/ui/cubit/chat_cubit.dart';
import 'package:convetchat/features/chat/ui/widgets/pinned_banner_andr.dart'
    show pinnedPreviewText;
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class const PinnedBannerCup({super.key}) extends StatelessWidget {
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
    final blue = CupertinoColors.systemBlue.resolveFrom(context);
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    final separator = CupertinoColors.separator.resolveFrom(context);

    return GestureDetector(
      behavior: .opaque,
      onTap: () => cubit.jumpToMessage(pinnedId),
      child: Container(
        decoration: BoxDecoration(
          color: CupertinoColors.secondarySystemBackground.resolveFrom(context),
          border: Border(bottom: BorderSide(color: separator, width: 0.5)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(CupertinoIcons.pin_fill, size: 20, color: blue),
            Container(
              width: 3,
              height: 36,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: blue,
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
                    style: TextStyle(
                      color: blue,
                      fontSize: 13,
                      fontWeight: .w600,
                    ),
                    maxLines: 1,
                    overflow: .ellipsis,
                  ),
                  Text(
                    message == null
                        ? 'Нажмите, чтобы перейти'
                        : '${message.senderName}: ${pinnedPreviewText(message)}',
                    style: TextStyle(color: secondary, fontSize: 14),
                    maxLines: 1,
                    overflow: .ellipsis,
                  ),
                ],
              ),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              onPressed: () => cubit.unpinMessage(),
              child: Icon(CupertinoIcons.xmark, size: 20, color: secondary),
            ),
          ],
        ),
      ),
    );
  }
}
