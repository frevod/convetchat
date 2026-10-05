import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/platform_style.dart';
import 'package:convetchat/features/chat/domain/entities/chat_message.dart';
import 'package:convetchat/features/chat/ui/cubit/chat_cubit.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter/material.dart' show Theme;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart' show Material, InkWell;

class const MessageReactions({
  super.key,
  required final ChatMessage message,
  final double indent = 0,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (message.reactions.isEmpty) return const SizedBox.shrink();
    final isCupertino = getIt<PlatformStyle>().isCupertino;
    return Padding(
      padding: EdgeInsets.only(left: 12 + indent, right: 12, top: 2),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        alignment: message.isOwn ? .end : .start,
        children: [
          for (final reaction in message.reactions)
            _ReactionAppear(
              key: ValueKey('reaction_${reaction.key}'),
              child: isCupertino
                  ? _CupReactionChip(message: message, reaction: reaction)
                  : _AndrReactionChip(message: message, reaction: reaction),
            ),
        ],
      ),
    );
  }
}

class const _AndrReactionChip({
  required final ChatMessage message,
  required final MessageReaction reaction,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final reacted = reaction.reacted;
    return Material(
      color: reacted ? scheme.primaryContainer : scheme.surfaceContainer,
      borderRadius: .circular(12),
      child: InkWell(
        borderRadius: .circular(12),
        onTap: () =>
            context.read<ChatCubit>().toggleReaction(message, reaction.key),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            borderRadius: .circular(12),
            border: .all(
              color: reacted ? scheme.primary : const Color(0x00000000),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: .min,
            children: [
              Text(reaction.key, style: const TextStyle(fontSize: 13)),
              if (reaction.count > 1) ...[
                const SizedBox(width: 3),
                Text(
                  '${reaction.count}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: .w600,
                    color: reacted
                        ? scheme.onPrimaryContainer
                        : scheme.onSurfaceVariant,
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

class const _CupReactionChip({
  required final ChatMessage message,
  required final MessageReaction reaction,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final blue = CupertinoColors.activeBlue.resolveFrom(context);
    final reacted = reaction.reacted;
    return GestureDetector(
      onTap: () =>
          context.read<ChatCubit>().toggleReaction(message, reaction.key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: reacted
              ? blue.withValues(alpha: 0.2)
              : CupertinoColors.tertiarySystemFill.resolveFrom(context),
          borderRadius: .circular(12),
          border: reacted ? .all(color: blue, width: 1) : null,
        ),
        child: Row(
          mainAxisSize: .min,
          children: [
            Text(reaction.key, style: const TextStyle(fontSize: 13)),
            if (reaction.count > 1) ...[
              const SizedBox(width: 3),
              Text(
                '${reaction.count}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: .w600,
                  color: reacted
                      ? blue
                      : CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class const _ReactionAppear({super.key, required final Widget child})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutBack,
      builder: (context, value, child) => Transform.scale(
        scale: value,
        alignment: .center,
        child: Opacity(opacity: value.clamp(0, 1), child: child),
      ),
      child: child,
    );
  }
}
