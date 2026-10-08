import 'package:convetchat/app/adaptive/adaptive_loading_indicator.dart';
import 'package:convetchat/features/chats/domain/entities/chat_room.dart';
import 'package:convetchat/features/chats/ui/cubit/chats_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_3_expressive/components/buttons/m3e_buttons.dart';
import 'package:material_3_expressive/components/cards/m3e_cards.dart';
import 'package:material_ui/material_ui.dart';

class const InviteItemAndr({
  super.key,
  required final ChatRoom invite,
  required final bool busy,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ChatsCubit>();
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: M3ECard(
        variant: .filled,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: .start,
          children: [
            Row(
              children: [
                Icon(Icons.mail_outlined, color: scheme.onSecondaryContainer),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    invite.displayName,
                    maxLines: 1,
                    overflow: .ellipsis,
                    style: TextStyle(
                      fontWeight: .w600,
                      color: scheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              invite.inviteReason ?? 'Вас пригласили в чат',
              style: TextStyle(
                fontSize: 13,
                color: scheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: M3EButton.tonal(
                    size: .sm,
                    onPressed: busy ? null : () => cubit.acceptInvite(invite),
                    child: busy
                        ? const SizedBox.square(
                            dimension: 18,
                            child: AdaptiveLoadingIndicator(),
                          )
                        : const Text('Принять'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: M3EButton.outlined(
                    size: .sm,
                    onPressed: busy ? null : () => cubit.declineInvite(invite),
                    child: const Text('Отклонить'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
