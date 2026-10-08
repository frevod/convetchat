import 'package:convetchat/app/adaptive/adaptive_buttons.dart';
import 'package:convetchat/app/adaptive/adaptive_loading_indicator.dart';
import 'package:convetchat/features/chats/domain/entities/chat_room.dart';
import 'package:convetchat/features/chats/ui/cubit/chats_cubit.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class const InviteItemCup({
  super.key,
  required final ChatRoom invite,
  required final bool busy,
}) extends StatelessWidget {
  static const double _spinnerSize = 18;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ChatsCubit>();
    final cardColor = CupertinoColors.systemGrey6.resolveFrom(context);
    final blue = CupertinoColors.activeBlue.resolveFrom(context);
    final grey = CupertinoColors.systemGrey.resolveFrom(context);
    final red = CupertinoColors.systemRed.resolveFrom(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: .start,
          children: [
            Row(
              children: [
                Icon(CupertinoIcons.mail, color: blue, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    invite.displayName,
                    maxLines: 1,
                    overflow: .ellipsis,
                    style: const TextStyle(fontSize: 15, fontWeight: .w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              invite.inviteReason ?? 'Вас пригласили в чат',
              style: TextStyle(fontSize: 13, color: grey),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: busy
                      ? const SizedBox.square(
                          dimension: _spinnerSize,
                          child: Center(child: AdaptiveLoadingIndicator()),
                        )
                      : AdaptiveButton.filled(
                          onPressed: () => cubit.acceptInvite(invite),
                          enabled: !busy,
                          child: const Text('Принять'),
                        ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AdaptiveButton.outlined(
                    onPressed: () => cubit.declineInvite(invite),
                    enabled: !busy,
                    child: Text('Отклонить', style: TextStyle(color: red)),
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
