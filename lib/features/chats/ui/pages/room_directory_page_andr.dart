import 'package:convetchat/app/adaptive/adaptive_loading_indicator.dart';
import 'package:convetchat/features/chats/ui/cubit/chat_search_cubit.dart';
import 'package:convetchat/features/chats/ui/widgets/public_room_hit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

class const RoomDirectoryPageAndr({super.key}) extends StatefulWidget {
  @override
  State<RoomDirectoryPageAndr> createState() => _RoomDirectoryPageState();
}

class _RoomDirectoryPageState() extends State<RoomDirectoryPageAndr> {
  late final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<ChatSearchCubit>();
    final state = cubit.state;

    return Scaffold(
      appBar: M3EAppBar.top(
        shapeFamily: .round,
        density: .compact,
        automaticallyImplyLeading: true,
        title: const Text('Каталог комнат'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _controller,
              onChanged: cubit.setQuery,
              textInputAction: .search,
              decoration: InputDecoration(
                hintText: 'Поиск публичных комнат',
                prefixIcon: const Icon(Icons.search_rounded),
                border: OutlineInputBorder(borderRadius: .circular(18)),
              ),
            ),
          ),
          Expanded(
            child: state.isSearching && state.publicHits.isEmpty
                ? const Center(child: AdaptiveLoadingIndicator())
                : state.publicHits.isEmpty
                ? const Center(child: Text('Комнаты не найдены'))
                : M3EList.scrollable(
                    itemCount: state.publicHits.length,
                    onTap: (index) => openPublicRoomPreview(
                      context: context,
                      room: state.publicHits[index],
                    ),
                    itemBuilder: (_, index) {
                      final room = state.publicHits[index];
                      return PublicRoomHit(
                        key: ValueKey(room.roomId),
                        room: room,
                        onPreview: () =>
                            openPublicRoomPreview(context: context, room: room),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
