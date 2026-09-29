import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/platform_style.dart';
import 'package:convetchat/features/chat/domain/entities/chat_message.dart';
import 'package:convetchat/features/chat/ui/cubit/chat_cubit.dart';
import 'package:convetchat/features/chat/ui/widgets/message_bubble_andr.dart';
import 'package:convetchat/features/chat/ui/widgets/message_bubble_cup.dart';
import 'package:convetchat/features/chat/ui/widgets/state_message.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

    final selected = context.select<ChatCubit, bool>(
      (cubit) => cubit.state.selectedEventIds.contains(message.id),
    );
    final inSelectionMode = context.select<ChatCubit, bool>(
      (cubit) => cubit.state.selectedEventIds.isNotEmpty,
    );

    final bubble = getIt<PlatformStyle>().isCupertino
        ? MessageBubbleCup(
            message: message,
            highlighted: highlighted,
            anchorKey: anchorKey,
            aboveSameSender: aboveSameSender,
            belowSameSender: belowSameSender,
          )
        : MessageBubbleAndr(
            message: message,
            highlighted: highlighted,
            anchorKey: anchorKey,
            aboveSameSender: aboveSameSender,
            belowSameSender: belowSameSender,
          );

    return _MessageSelection(
      message: message,
      selected: selected,
      inSelectionMode: inSelectionMode,
      child: bubble,
    );
  }
}

class const _MessageSelection({
  required final ChatMessage message,
  required final bool selected,
  required final bool inSelectionMode,
  required final Widget child,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cubit = context.read<ChatCubit>();

    final content = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: () {
        if (selected || inSelectionMode) {
          cubit.toggleSelection(message.id);
        } else {
          cubit.enterSelection(message.id);
        }
      },
      onTap: inSelectionMode ? () => cubit.toggleSelection(message.id) : null,
      child: child,
    );

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
              child: Icon(Icons.check_circle, size: 16, color: scheme.primary),
            ),
          ),
        ),
      ],
    );
  }
}
