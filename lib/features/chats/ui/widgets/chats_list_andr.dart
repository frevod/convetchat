import 'package:convetchat/app/adaptive/adaptive_loading_indicator.dart';
import 'package:convetchat/features/chats/ui/cubit/chats_state.dart';
import 'package:convetchat/features/chats/ui/widgets/invite_item.dart';
import 'package:convetchat/features/chats/ui/widgets/room_item.dart';
import 'package:material_ui/material_ui.dart';

class const ChatsListAndr({super.key, required final ChatsState state})
    extends StatelessWidget {
  bool get _isEmpty => state.rooms.isEmpty && state.invites.isEmpty;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading || (!state.synced && _isEmpty)) {
      return const Center(child: AdaptiveLoadingIndicator());
    }
    if (_isEmpty) {
      return Center(
        child: Text(
          'Пока нет чатов',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }
    return ListView.separated(
      itemCount: state.invites.length + state.rooms.length,
      separatorBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(left: 76),
          child: Divider(height: 0.2),
        );
      },
      itemBuilder: (context, index) {
        if (index < state.invites.length) {
          final invite = state.invites[index];
          return InviteItem(
            key: ValueKey('invite_${invite.id}'),
            invite: invite,
            busy: state.actionInviteId == invite.id,
          );
        }
        final room = state.rooms[index - state.invites.length];
        return RoomItem(key: ValueKey(room.id), room: room);
      },
    );
  }
}
