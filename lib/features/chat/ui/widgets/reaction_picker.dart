import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/platform_style.dart';
import 'package:convetchat/features/chat/domain/entities/chat_message.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter/material.dart' show Icons, Theme, showModalBottomSheet;
import 'package:material_ui/material_ui.dart'
    show Material, InkWell, IconButton;

const List<String> kQuickReactions = ['👍', '❤️', '😂', '😮', '😢', '🔥'];

const List<String> kExtraReactions = [
  '❤️',
  '👍',
  '👎',
  '😂',
  '😮',
  '😢',
  '🔥',
  '🎉',
  '😡',
  '😍',
  '🤔',
  '👏',
  '🙏',
  '👀',
  '💯',
  '✅',
  '❌',
  '⭐',
  '💔',
  '🥳',
  '😎',
  '🤯',
  '😴',
  '🤝',
  '👋',
  '✋',
  '💪',
  '🫶',
  '😅',
  '😇',
  '🥲',
  '😱',
  '🤣',
  '🙌',
  '🤷',
  '💡',
];

class const ReactionPickerRow({
  super.key,
  required final ChatMessage message,
  required final ValueChanged<String> onPicked,
  final VoidCallback? onExpand,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final reactedKeys = {
      for (final r in message.reactions)
        if (r.reacted) r.key,
    };
    final isCupertino = getIt<PlatformStyle>().isCupertino;
    return SingleChildScrollView(
      scrollDirection: .horizontal,
      child: Row(
        mainAxisSize: .min,
        mainAxisAlignment: .center,
        children: [
          for (final emoji in kQuickReactions)
            _QuickEmoji(
              emoji: emoji,
              selected: reactedKeys.contains(emoji),
              cupertino: isCupertino,
              onTap: () => onPicked(emoji),
            ),
          if (onExpand != null)
            if (isCupertino)
              CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: const Size(40, 40),
                onPressed: onExpand,
                child: const Icon(CupertinoIcons.add, size: 22),
              )
            else
              IconButton(
                tooltip: 'Больше реакций',
                visualDensity: .compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                icon: const Icon(Icons.add_reaction_outlined, size: 22),
                onPressed: onExpand,
              ),
        ],
      ),
    );
  }
}

class const _QuickEmoji({
  required final String emoji,
  required final bool selected,
  required final bool cupertino,
  required final VoidCallback onTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final selectedBg = cupertino
        ? CupertinoColors.activeBlue.resolveFrom(context).withValues(alpha: 0.2)
        : Theme.of(context).colorScheme.primaryContainer;
    final content = Container(
      width: 40,
      height: 40,
      alignment: .center,
      decoration: BoxDecoration(
        color: selected ? selectedBg : const Color(0x00000000),
        borderRadius: .circular(20),
      ),
      child: Text(
        emoji,
        style: const TextStyle(fontSize: 22),
        textAlign: .center,
      ),
    );
    if (cupertino) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 1),
        child: GestureDetector(onTap: onTap, child: content),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: Material(
        color: const Color(0x00000000),
        borderRadius: .circular(20),
        child: InkWell(
          borderRadius: .circular(20),
          onTap: onTap,
          child: content,
        ),
      ),
    );
  }
}

Future<String?> showExtraReactionsSheet(BuildContext context) {
  if (getIt<PlatformStyle>().isCupertino) {
    return showCupertinoModalPopup<String>(
      context: context,
      builder: (sheetContext) => Container(
        height: MediaQuery.sizeOf(sheetContext).height * 0.45,
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground.resolveFrom(sheetContext),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: .stretch,
              children: [
                Text(
                  'Выберите реакцию',
                  style: const TextStyle(fontSize: 17, fontWeight: .w600),
                  textAlign: .center,
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _EmojiGrid(onPick: Navigator.of(sheetContext).pop),
                ),
                CupertinoButton(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  child: const Text('Отмена'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  return showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        child: Column(
          mainAxisSize: .min,
          crossAxisAlignment: .stretch,
          children: [
            Text(
              'Выберите реакцию',
              style: Theme.of(sheetContext).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Flexible(child: _EmojiGrid(onPick: Navigator.of(sheetContext).pop)),
          ],
        ),
      ),
    ),
  );
}

class const _EmojiGrid({required final ValueChanged<String> onPick})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isCupertino = getIt<PlatformStyle>().isCupertino;
    return GridView.builder(
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
      ),
      itemCount: kExtraReactions.length,
      itemBuilder: (context, index) {
        final emoji = kExtraReactions[index];
        final cell = Center(
          child: Text(emoji, style: const TextStyle(fontSize: 26)),
        );
        if (isCupertino) {
          return GestureDetector(onTap: () => onPick(emoji), child: cell);
        }
        return Material(
          color: const Color(0x00000000),
          borderRadius: .circular(16),
          child: InkWell(
            borderRadius: .circular(16),
            onTap: () => onPick(emoji),
            child: cell,
          ),
        );
      },
    );
  }
}
