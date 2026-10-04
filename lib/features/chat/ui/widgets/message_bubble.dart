import 'dart:async';

import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/platform_style.dart';
import 'package:convetchat/features/chat/domain/entities/chat_message.dart';
import 'package:convetchat/features/chat/ui/cubit/chat_cubit.dart';
import 'package:convetchat/features/chat/ui/widgets/message_bubble_andr.dart';
import 'package:convetchat/features/chat/ui/widgets/message_bubble_cup.dart';
import 'package:convetchat/features/chat/ui/widgets/message_selection.dart';
import 'package:convetchat/features/chat/ui/widgets/reaction_picker.dart';
import 'package:convetchat/features/chat/ui/widgets/state_message.dart';
import 'package:cupertino_ui/cupertino_ui.dart' as cup;
import 'package:flutter/services.dart';
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
  required this.message,
  required this.selected,
  required this.inSelectionMode,
  required this.isCupertino,
  required this.anchorKey,
  required this.child,
}) extends StatefulWidget {
  final ChatMessage message;
  final bool selected;
  final bool inSelectionMode;
  final bool isCupertino;
  final GlobalKey? anchorKey;
  final Widget child;

  @override
  State<_MessageSelection> createState() => _MessageSelectionState();
}

class _MessageSelectionState() extends State<_MessageSelection> {
  Timer? _tapTimer;

  static const _tapDelay = Duration(milliseconds: 200);

  @override
  void dispose() {
    _tapTimer?.cancel();
    super.dispose();
  }

  ChatMessage get message => widget.message;

  void _onLongPress(VoidCallback openMenu) {
    _tapTimer?.cancel();
    if (message.status == MessageStatus.sending) {
      openMenu();
      return;
    }
    final cubit = context.read<ChatCubit>();
    if (widget.inSelectionMode) {
      cubit.toggleSelection(message.id);
    } else {
      cubit.enterSelection(message.id);
    }
  }

  void _onTap(VoidCallback openMenu) {
    if (widget.inSelectionMode) {
      if (message.status != MessageStatus.sending) {
        context.read<ChatCubit>().toggleSelection(message.id);
      }
      return;
    }
    if (message.status == MessageStatus.sending) {
      openMenu();
      return;
    }
    _tapTimer?.cancel();
    _tapTimer = Timer(_tapDelay, () {
      if (!mounted) return;
      if (widget.inSelectionMode) return;
      openMenu();
    });
  }

  void _onDoubleTap() {
    if (widget.inSelectionMode) return;
    _tapTimer?.cancel();
    if (!message.canReact) return;
    unawaited(HapticFeedback.lightImpact());
    unawaited(context.read<ChatCubit>().toggleHeart(message));
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ChatCubit>();

    final anchor = widget.anchorKey;
    if (message.status == MessageStatus.sending && message.media != null) {
      return widget.child;
    }
    final useActionsMenu =
        !widget.inSelectionMode && !widget.isCupertino && anchor != null;

    if (useActionsMenu) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onLongPress: () => _onLongPress(() => _showAndrMenu(context)),
        onTap: () => _onTap(() => _showAndrMenu(context)),
        onDoubleTap: _onDoubleTap,
        child: widget.child,
      );
    }

    Widget content = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: () => _onLongPress(() => _showCupertinoMenu(context)),
      onTap: widget.isCupertino
          ? () => _onTap(() => _showCupertinoMenu(context))
          : () {
              if (widget.inSelectionMode) {
                cubit.toggleSelection(message.id);
              }
            },
      onDoubleTap: _onDoubleTap,
      child: widget.child,
    );

    if (widget.isCupertino) return content;
    return _SelectionHighlight(
      message: message,
      selected: widget.selected,
      inSelectionMode: widget.inSelectionMode,
      child: content,
    );
  }

  Future<void> _showAndrMenu(BuildContext context) async {
    final cubit = context.read<ChatCubit>();
    final msg = message;
    if (msg.status == MessageStatus.sending) {
      final action = await M3EBottomSheet.show<String>(
        context,
        builder: (sheetContext) {
          final scheme = Theme.of(sheetContext).colorScheme;
          final items = [
            M3EListItem(
              headline: 'Отменить отправку',
              leading: Icon(Icons.close_rounded, color: scheme.error),
              onTap: () => Navigator.of(sheetContext).pop('cancel'),
            ),
          ];
          return SafeArea(
            child: M3EList.scrollable(
              shrinkWrap: true,
              itemCount: items.length,
              onTap: (index) => items[index].onTap?.call(),
              itemBuilder: (context, index) => items[index],
            ),
          );
        },
      );
      if (action == 'cancel') unawaited(cubit.cancelSendMessage(msg));
      return;
    }
    final editable = msg.isBody;
    final pinned = cubit.state.pinnedEventIds.contains(msg.id);
    final action = await M3EBottomSheet.show<String>(
      context,
      builder: (sheetContext) {
        final scheme = Theme.of(sheetContext).colorScheme;
        final actions = [
          if (editable)
            M3EListItem(
              headline: 'Копировать',
              leading: const Icon(Icons.copy_rounded),
              onTap: () => Navigator.of(sheetContext).pop('copy'),
            ),
          if (editable && msg.isOwn)
            M3EListItem(
              headline: 'Изменить',
              leading: const Icon(Icons.edit_rounded),
              onTap: () => Navigator.of(sheetContext).pop('edit'),
            ),
          if (!msg.isState)
            M3EListItem(
              headline: pinned ? 'Открепить' : 'Закрепить',
              leading: Icon(
                pinned ? Icons.push_pin_outlined : Icons.push_pin_rounded,
              ),
              onTap: () => Navigator.of(sheetContext).pop('pin'),
            ),
          if (!msg.isState)
            M3EListItem(
              headline: 'Переслать',
              leading: const Icon(Icons.turn_right_rounded),
              onTap: () => Navigator.of(sheetContext).pop('forward'),
            ),
          M3EListItem(
            headline: 'Удалить',
            leading: Icon(Icons.delete_outline_rounded, color: scheme.error),
            onTap: () => Navigator.of(sheetContext).pop('delete'),
          ),
        ];
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.6,
            ),
            child: Column(
              mainAxisSize: .min,
              crossAxisAlignment: .stretch,
              children: [
                if (msg.canReact) ...[
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest,
                        borderRadius: .circular(24),
                      ),
                      child: ReactionPickerRow(
                        message: msg,
                        onPicked: (emoji) =>
                            Navigator.of(sheetContext).pop('react:$emoji'),
                        onExpand: () => Navigator.of(sheetContext).pop('more'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Flexible(
                  child: M3EList.scrollable(
                    shrinkWrap: true,
                    itemCount: actions.length,
                    onTap: (index) => actions[index].onTap?.call(),
                    itemBuilder: (context, index) => actions[index],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (!context.mounted) return;
    if (action == null) return;
    if (action == 'more') {
      final extra = await showExtraReactionsSheet(context);
      if (extra == null || !context.mounted) return;
      unawaited(cubit.toggleReaction(msg, extra));
      return;
    }
    const reactPrefix = 'react:';
    if (action.startsWith(reactPrefix)) {
      unawaited(
        cubit.toggleReaction(msg, action.substring(reactPrefix.length)),
      );
      return;
    }
    switch (action) {
      case 'copy':
        unawaited(cubit.copyMessage(msg));
      case 'edit':
        cubit.editMessage(msg);
      case 'pin':
        if (pinned) {
          unawaited(cubit.unpinMessage());
        } else {
          unawaited(cubit.pinMessage(msg));
        }
      case 'forward':
        cubit.enterSelection(msg.id);
        await openForwardPickerAndPick(context);
        if (!cubit.isClosed) cubit.clearSelection();
      case 'delete':
        unawaited(cubit.deleteMessage(msg));
    }
  }

  Future<void> _showCupertinoMenu(BuildContext context) async {
    final cubit = context.read<ChatCubit>();
    final msg = message;
    if (msg.status == MessageStatus.sending) {
      await cup.showCupertinoModalPopup<String>(
        context: context,
        builder: (sheetContext) => cup.CupertinoActionSheet(
          actions: [
            cup.CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.of(sheetContext).pop('cancel');
                unawaited(cubit.cancelSendMessage(msg));
              },
              child: const Text('Отменить отправку'),
            ),
          ],
          cancelButton: cup.CupertinoActionSheetAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(sheetContext).pop(),
            child: const Text('Отмена'),
          ),
        ),
      );
      return;
    }
    final editable = msg.isBody;
    final pinned = cubit.state.pinnedEventIds.contains(msg.id);
    await cup.showCupertinoModalPopup<String>(
      context: context,
      builder: (sheetContext) => cup.CupertinoActionSheet(
        message: msg.canReact
            ? ReactionPickerRow(
                message: msg,
                onPicked: (emoji) {
                  Navigator.of(sheetContext).pop();
                  unawaited(cubit.toggleReaction(msg, emoji));
                },
                onExpand: () async {
                  Navigator.of(sheetContext).pop();
                  final extra = await showExtraReactionsSheet(context);
                  if (extra == null || !context.mounted) return;
                  unawaited(cubit.toggleReaction(msg, extra));
                },
              )
            : null,
        actions: [
          if (editable)
            cup.CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(sheetContext).pop('copy');
                unawaited(cubit.copyMessage(msg));
              },
              child: const Text('Копировать'),
            ),
          if (editable && msg.isOwn)
            cup.CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(sheetContext).pop('edit');
                cubit.editMessage(msg);
              },
              child: const Text('Изменить'),
            ),
          if (!msg.isState)
            cup.CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(sheetContext).pop('pin');
                if (pinned) {
                  unawaited(cubit.unpinMessage());
                } else {
                  unawaited(cubit.pinMessage(msg));
                }
              },
              child: Text(pinned ? 'Открепить' : 'Закрепить'),
            ),
          if (!msg.isState)
            cup.CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(sheetContext).pop('forward');
                cubit.enterSelection(msg.id);
                unawaited(
                  openForwardPickerAndPick(context).then((_) {
                    if (!cubit.isClosed) cubit.clearSelection();
                  }),
                );
              },
              child: const Text('Переслать'),
            ),
          cup.CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.of(sheetContext).pop('delete');
              unawaited(cubit.deleteMessage(msg));
            },
            child: const Text('Удалить'),
          ),
        ],
        cancelButton: cup.CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(sheetContext).pop(),
          child: const Text('Отмена'),
        ),
      ),
    );
  }
}

class const _SelectionHighlight({
  required this.message,
  required this.selected,
  required this.inSelectionMode,
  required this.child,
}) extends StatelessWidget {
  final ChatMessage message;
  final bool selected;
  final bool inSelectionMode;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final leftShift = !message.isOwn && selected ? 28.0 : 0.0;
    final positioned = leftShift > 0
        ? Padding(
            padding: EdgeInsets.only(left: leftShift),
            child: child,
          )
        : child;

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
