import 'package:convetchat/app/adaptive/adaptive_loading_indicator.dart';
import 'package:convetchat/features/chats/ui/cubit/chats_state.dart';
import 'package:convetchat/features/chats/ui/widgets/invite_item.dart';
import 'package:convetchat/features/chats/ui/widgets/room_item_andr.dart';
import 'package:convetchat/features/chats/ui/widgets/room_menu_andr.dart';
import 'package:go_router/go_router.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

class const ChatsListAndr({super.key, required final ChatsState state})
    extends StatefulWidget {
  @override
  State<ChatsListAndr> createState() => _ChatsListAndrState();
}

class _ChatsListAndrState() extends State<ChatsListAndr> {
  final Map<String, BuildContext> _rowContexts = {};

  void _recordRowContext(String roomId, BuildContext rowContext) {
    _rowContexts[roomId] = rowContext;
  }

  Rect _anchorFor(String roomId) {
    final rowContext = _rowContexts[roomId];
    if (rowContext != null && rowContext.mounted) {
      final box = rowContext.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize) {
        return box.localToGlobal(Offset.zero) & box.size;
      }
    }
    final size = MediaQuery.sizeOf(context);
    return Offset(size.width / 2, size.height - 200) & const Size(1, 1);
  }

  Future<void> _onLongPress(int index) async {
    final rooms = widget.state.rooms;
    if (index < 0 || index >= rooms.length) return;
    final room = rooms[index];
    await RoomMenuAndr.show(context, room, _anchorFor(room.id));
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    if (state.rooms.isNotEmpty) {
      final ids = {for (final room in state.rooms) room.id};
      _rowContexts.removeWhere((id, _) => !ids.contains(id));
    }

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
    return CustomScrollView(
      slivers: [
        if (state.invites.isNotEmpty)
          SliverList.builder(
            itemCount: state.invites.length,
            itemBuilder: (context, index) {
              final invite = state.invites[index];
              return InviteItem(
                key: ValueKey('invite_${invite.id}'),
                invite: invite,
                busy: state.actionInviteId == invite.id,
              );
            },
          ),
        if (state.rooms.isNotEmpty)
          M3EList.sliver(
            itemCount: state.rooms.length,
            onTap: (index) => context.push('/chat/${state.rooms[index].id}'),
            onLongPress: _onLongPress,
            itemBuilder: (context, index) {
              final room = state.rooms[index];
              return buildRoomListItem(
                context,
                room,
                key: ValueKey('room_${room.id}'),
                onRowContext: _recordRowContext,
              );
            },
          ),
      ],
    );
  }

  bool get _isEmpty =>
      widget.state.rooms.isEmpty && widget.state.invites.isEmpty;
}
