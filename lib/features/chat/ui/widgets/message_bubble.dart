import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/platform_style.dart';
import 'package:convetchat/features/chat/domain/entities/chat_message.dart';
import 'package:convetchat/features/chat/ui/cubit/chat_cubit.dart';
import 'package:convetchat/features/chat/ui/widgets/message_bubble_andr.dart';
import 'package:convetchat/features/chat/ui/widgets/message_bubble_cup.dart';
import 'package:convetchat/features/chat/ui/widgets/state_message.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

class const MessageBubble({
  super.key,
  required final ChatMessage message,

  final bool highlighted = false,

  final GlobalKey? anchorKey,

  final bool isCollapsed = false,

  final bool expanded = false,

  final VoidCallback? onExpand,

  final bool aboveSameSender = false,

  final bool belowSameSender = false,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (message.isState) {
      return StateMessage(
        message: message,
        isCollapsed: isCollapsed,
        expanded: expanded,
        onExpand: onExpand,
      );
    }

    final isCupertino = getIt<PlatformStyle>().isCupertino;
    final selected = context.select<ChatCubit, bool>(
      (cubit) => cubit.state.selectedEventIds.contains(message.id),
    );
    final inSelectionMode = context.select<ChatCubit, bool>(
      (cubit) => cubit.state.selectedEventIds.isNotEmpty,
    );

    Widget platformBubble({
      required GlobalKey? anchor,
      bool previewOnly = false,
    }) => isCupertino
        ? MessageBubbleCup(
            message: message,
            highlighted: highlighted,
            anchorKey: anchor,
            aboveSameSender: aboveSameSender,
            belowSameSender: belowSameSender,
          )
        : MessageBubbleAndr(
            message: message,
            highlighted: highlighted,
            anchorKey: anchor,
            aboveSameSender: aboveSameSender,
            belowSameSender: belowSameSender,
            previewOnly: previewOnly,
          );

    return _MessageSelection(
      message: message,
      selected: selected,
      inSelectionMode: inSelectionMode,
      isCupertino: isCupertino,
      anchorKey: anchorKey,
      child: platformBubble(anchor: anchorKey),
    );
  }
}

class const _MessageSelection({
  required final ChatMessage message,
  required final bool selected,
  required final bool inSelectionMode,
  required final bool isCupertino,
  required final GlobalKey? anchorKey,
  required final Widget child,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cubit = context.read<ChatCubit>();
    final isPinned = context.select<ChatCubit, bool>(
      (c) => c.state.pinnedEventIds.contains(message.id),
    );

    final anchor = anchorKey;
    final useActionsMenu = !inSelectionMode && !isCupertino && anchor != null;

    Widget withSelectionHighlight(Widget content) {
      final leftShift = !message.isOwn && selected ? 28.0 : 0.0;
      final positioned = leftShift > 0
          ? Padding(
              padding: EdgeInsets.only(left: leftShift),
              child: content,
            )
          : content;

      if (!inSelectionMode || !selected) return positioned;

      return Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.16),
              ),
              child: Align(
                alignment: .centerLeft,
                child: SizedBox(
                  width: 3,
                  child: ColoredBox(color: scheme.primary),
                ),
              ),
            ),
          ),
          positioned,
          Positioned(
            left: 6,
            top: 0,
            bottom: 0,
            child: IgnorePointer(
              child: Center(
                child: Icon(
                  Icons.check_circle,
                  size: 16,
                  color: scheme.primary,
                ),
              ),
            ),
          ),
        ],
      );
    }

    void onLongPress() {
      if (inSelectionMode) {
        cubit.toggleSelection(message.id);
      } else {
        cubit.enterSelection(message.id);
      }
    }

    if (useActionsMenu) {
      return M3EMenu(
        position: message.isOwn ? .bottomEnd : .bottomStart,
        anchorBuilder: (_, open) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onLongPress: onLongPress,
          onTap: () {
            if (inSelectionMode) {
              cubit.toggleSelection(message.id);
            } else {
              open();
            }
          },
          child: child,
        ),
        children: _menuEntries(cubit, isPinned),
      );
    }

    final content = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: onLongPress,
      onTap: () {
        if (inSelectionMode) {
          cubit.toggleSelection(message.id);
        }
      },
      child: child,
    );

    return withSelectionHighlight(content);
  }

  List<M3EMenuNode> _menuEntries(ChatCubit cubit, bool isPinned) {
    final editable = message.isBody;
    return [
      if (editable)
        M3EMenuEntry(
          label: 'Копировать',
          leading: const Icon(Icons.copy_rounded),
          onPressed: () => cubit.copyMessage(message),
        ),
      if (editable && message.isOwn)
        M3EMenuEntry(
          label: 'Изменить',
          leading: const Icon(Icons.edit_rounded),
          onPressed: () => cubit.editMessage(message),
        ),
      if (!message.isState)
        M3EMenuEntry(
          label: isPinned ? 'Открепить' : 'Закрепить',
          leading: Icon(
            isPinned ? Icons.push_pin_outlined : Icons.push_pin_rounded,
          ),
          onPressed: () {
            if (isPinned) {
              cubit.unpinMessage();
            } else {
              cubit.pinMessage(message);
            }
          },
        ),
      const M3EMenuDivider(),
      M3EMenuEntry(
        label: 'Удалить',
        leading: const Icon(Icons.delete_outline_rounded),
        isDestructive: true,
        onPressed: () => cubit.deleteMessage(message),
      ),
    ];
  }
}
