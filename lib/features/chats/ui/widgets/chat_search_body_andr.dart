import 'package:convetchat/app/adaptive/adaptive_loading_indicator.dart';
import 'package:convetchat/app/adaptive/adaptive_snackbar.dart';
import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/features/chats/domain/entities/chat_room.dart';
import 'package:convetchat/features/chats/domain/entities/searched_message.dart';
import 'package:convetchat/features/chats/domain/entities/search_filter.dart';
import 'package:convetchat/features/chats/ui/cubit/chat_search_cubit.dart';
import 'package:convetchat/features/chats/ui/cubit/chat_search_state.dart';
import 'package:convetchat/features/chats/ui/cubit/chats_cubit.dart';
import 'package:convetchat/features/chats/ui/cubit/chats_state.dart';
import 'package:convetchat/features/chats/ui/widgets/message_search_hit_andr.dart';
import 'package:convetchat/features/chats/ui/widgets/person_search_hit_andr.dart';
import 'package:convetchat/features/chats/ui/widgets/public_room_hit.dart';
import 'package:convetchat/features/chats/ui/widgets/room_search_hit_andr.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

class const ChatSearchBodyAndr({
  super.key,
  required final M3ESearchController searchController,
  required final ChatSearchCubit searchCubit,
  required final ChatsCubit chatsCubit,
}) extends StatelessWidget {
  static const _maxHits = 30;

  @override
  Widget build(BuildContext context) {
    return BlocListener<ChatSearchCubit, ChatSearchState>(
      bloc: searchCubit,
      listener: (context, state) {
        if (state.errorMessage != null) {
          AdaptiveSnackbar.show(
            context: context,
            message: state.errorMessage!,
            type: .error,
          );
          searchCubit.clearError();
        }
      },
      child: BlocBuilder<ChatSearchCubit, ChatSearchState>(
        bloc: searchCubit,
        builder: (context, state) {
          return Column(
            mainAxisSize: .min,
            crossAxisAlignment: .stretch,
            children: [
              SingleChildScrollView(
                scrollDirection: .horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    for (final filter in SearchFilter.values)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: M3EChip(
                          type: .filter,
                          label: filter.label,
                          selected: state.filter == filter,
                          onPressed: () => searchCubit.setFilter(filter),
                        ),
                      ),
                  ],
                ),
              ),
              if (state.isSearching)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: SizedBox.square(
                      dimension: 24,
                      child: AdaptiveLoadingIndicator(),
                    ),
                  ),
                ),
              _Results(
                searchController: searchController,
                searchCubit: searchCubit,
                chatsCubit: chatsCubit,
                onPersonTap: (userId, label) => _openDirectChat(
                  searchCubit,
                  searchController,
                  userId,
                  label,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class const _Results({
  required final M3ESearchController searchController,
  required final ChatSearchCubit searchCubit,
  required final ChatsCubit chatsCubit,
  required final Future<void> Function(String userId, String label) onPersonTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatSearchCubit, ChatSearchState>(
      bloc: searchCubit,
      builder: (context, search) {
        return switch (search.filter) {
          SearchFilter.chats => BlocBuilder<ChatsCubit, ChatsState>(
            bloc: chatsCubit,
            builder: (context, chats) {
              final query = search.query.trim().toLowerCase();
              final matches =
                  (query.isEmpty
                          ? chats.rooms
                          : chats.rooms.where(
                              (room) => room.displayName.toLowerCase().contains(
                                query,
                              ),
                            ))
                      .take(ChatSearchBodyAndr._maxHits)
                      .toList();
              if (matches.isEmpty && !chats.isLoading) {
                return const _Hint(text: 'Чаты не найдены');
              }
              return M3EList(
                itemCount: matches.length,
                onTap: (index) => _openRoom(searchController, matches[index]),
                itemBuilder: (context, index) {
                  final room = matches[index];
                  return RoomSearchHitAndr(
                    key: ValueKey(room.id),
                    room: room,
                    searchController: searchController,
                  );
                },
              );
            },
          ),
          SearchFilter.messages =>
            search.query.trim().isEmpty
                ? const _Hint(text: 'Введите текст для поиска по сообщениям')
                : search.messageHits.isEmpty && !search.isSearching
                ? const _Hint(text: 'Сообщения не найдены')
                : Builder(
                    builder: (context) {
                      final hits = search.messageHits
                          .take(ChatSearchBodyAndr._maxHits)
                          .toList();
                      return M3EList(
                        itemCount: hits.length,
                        onTap: (index) =>
                            _openMessage(searchController, hits[index]),
                        itemBuilder: (context, index) {
                          final hit = hits[index];
                          return MessageSearchHitAndr(
                            key: ValueKey('${hit.roomId}_${hit.eventId}'),
                            hit: hit,
                            searchController: searchController,
                          );
                        },
                      );
                    },
                  ),
          SearchFilter.people =>
            search.query.trim().isEmpty
                ? const _Hint(text: 'Введите имя или id пользователя')
                : search.userHits.isEmpty && !search.isSearching
                ? const _Hint(text: 'Пользователи не найдены')
                : Builder(
                    builder: (context) {
                      final users = search.userHits
                          .take(ChatSearchBodyAndr._maxHits)
                          .toList();
                      return M3EList(
                        itemCount: users.length,
                        onTap: (index) => onPersonTap(
                          users[index].userId,
                          users[index].displayName,
                        ),
                        itemBuilder: (context, index) {
                          final user = users[index];
                          return PersonSearchHitAndr(
                            key: ValueKey(user.userId),
                            user: user,
                            busy: searchCubit.state.isCreatingChat,
                            onTap: () =>
                                onPersonTap(user.userId, user.displayName),
                          );
                        },
                      );
                    },
                  ),
          SearchFilter.publicRooms =>
            search.publicHits.isEmpty && !search.isSearching
                ? const _Hint(text: 'Комнаты не найдены')
                : Builder(
                    builder: (context) {
                      final rooms = search.publicHits
                          .take(ChatSearchBodyAndr._maxHits)
                          .toList();
                      return M3EList(
                        itemCount: rooms.length,
                        onTap: (index) => joinAndOpenPublicRoom(
                          searchCubit: searchCubit,
                          room: rooms[index],
                          searchController: searchController,
                        ),
                        itemBuilder: (context, index) {
                          final room = rooms[index];
                          return PublicRoomHit(
                            key: ValueKey(room.roomId),
                            room: room,
                            busy: search.joiningRoomId == room.roomId,
                            onJoin: () => joinAndOpenPublicRoom(
                              searchCubit: searchCubit,
                              room: room,
                              searchController: searchController,
                            ),
                          );
                        },
                      );
                    },
                  ),
        };
      },
    );
  }
}

class const _Hint({required final String text}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(child: Text(text)),
    );
  }
}

Future<void> _openDirectChat(
  ChatSearchCubit searchCubit,
  M3ESearchController controller,
  String userId,
  String label,
) async {
  final roomId = await searchCubit.openDirectChat(userId);
  if (roomId == null) return;
  if (controller.isOpen) controller.closeView(label);
  getIt<GoRouter>().push('/chat/$roomId');
}

void _openRoom(M3ESearchController controller, ChatRoom room) {
  controller.closeView(room.displayName);
  getIt<GoRouter>().push('/chat/${room.id}');
}

void _openMessage(M3ESearchController controller, SearchedMessage hit) {
  controller.closeView(hit.body);
  getIt<GoRouter>().push('/chat/${hit.roomId}', extra: hit.eventId);
}
