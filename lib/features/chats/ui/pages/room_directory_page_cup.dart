import 'package:convetchat/app/adaptive/adaptive_loading_indicator.dart';
import 'package:convetchat/app/adaptive/adaptive_text_field.dart';
import 'package:convetchat/features/chats/ui/cubit/chat_search_cubit.dart';
import 'package:convetchat/features/chats/ui/widgets/public_room_hit.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class const RoomDirectoryPageCup({super.key}) extends StatefulWidget {
  @override
  State<RoomDirectoryPageCup> createState() => _RoomDirectoryPageState();
}

class _RoomDirectoryPageState() extends State<RoomDirectoryPageCup> {
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

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Каталог комнат'),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: AdaptiveTextField(
                controller: _controller,
                onChanged: cubit.setQuery,
                label: 'Поиск публичных комнат',
              ),
            ),
            Expanded(
              child: state.isSearching && state.publicHits.isEmpty
                  ? const Center(child: AdaptiveLoadingIndicator())
                  : state.publicHits.isEmpty
                  ? const Center(child: Text('Комнаты не найдены'))
                  : ListView.builder(
                      itemCount: state.publicHits.length,
                      itemBuilder: (context, index) {
                        final room = state.publicHits[index];
                        return PublicRoomHit(
                          key: ValueKey(room.roomId),
                          room: room,
                          onPreview: () => openPublicRoomPreview(
                            context: context,
                            room: room,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
