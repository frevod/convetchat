import 'dart:async';

import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/features/chats/domain/entities/search_filter.dart';
import 'package:convetchat/features/chats/domain/repositories/chats_repository.dart';
import 'package:convetchat/features/chats/ui/cubit/chat_search_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talker_flutter/talker_flutter.dart';

class ChatSearchCubit(final ChatsRepository _repository)
    extends Cubit<ChatSearchState> {
  this : super(const ChatSearchState());

  static const _debounceDelay = Duration(milliseconds: 400);

  Timer? _debounce;

  int _searchGeneration = 0;

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }

  void setQuery(String query) {
    if (query == state.query) return;
    _searchGeneration++;
    emit(state.copyWith(query: () => query));
    if (!_needsServerSearch(query)) {
      _debounce?.cancel();
      emit(state.copyWith(isSearching: () => false));
      return;
    }
    emit(state.copyWith(isSearching: () => true));
    _debounce?.cancel();
    _debounce = Timer(_debounceDelay, () => _run(query.trim()));
  }

  void setFilter(SearchFilter filter) {
    if (filter == state.filter) return;
    _searchGeneration++;
    emit(state.copyWith(filter: () => filter));
    final query = state.query.trim();
    if (!_needsServerSearch(state.query)) {
      _debounce?.cancel();
      emit(state.copyWith(isSearching: () => false));
      return;
    }
    emit(state.copyWith(isSearching: () => true));
    _debounce?.cancel();
    _debounce = Timer(_debounceDelay, () => _run(query));
  }

  bool _needsServerSearch(String query) {
    return switch (state.filter) {
      SearchFilter.chats => false,
      SearchFilter.messages => query.trim().isNotEmpty,
      SearchFilter.people => query.trim().isNotEmpty,
      SearchFilter.publicRooms => true,
    };
  }

  Future<void> _run(String query) async {
    final generation = ++_searchGeneration;
    try {
      switch (state.filter) {
        case SearchFilter.chats:
          break;
        case SearchFilter.messages:
          final hits = await _repository.searchMessages(query);
          if (isClosed || generation != _searchGeneration) return;
          emit(
            state.copyWith(messageHits: () => hits, isSearching: () => false),
          );
        case SearchFilter.people:
          final hits = await _repository.searchUsers(query);
          if (isClosed || generation != _searchGeneration) return;
          emit(state.copyWith(userHits: () => hits, isSearching: () => false));
        case SearchFilter.publicRooms:
          final hits = await _repository.searchPublicRooms(query);
          if (isClosed || generation != _searchGeneration) return;
          emit(
            state.copyWith(publicHits: () => hits, isSearching: () => false),
          );
      }
    } catch (e, s) {
      if (isClosed || generation != _searchGeneration) return;
      getIt<Talker>().error('[chats] search failed', e, s);
      emit(
        state.copyWith(
          isSearching: () => false,
          errorMessage: () => 'Поиск не удался. Попробуйте снова',
        ),
      );
    }
  }

  Future<String?> openDirectChat(String userId) async {
    if (state.isCreatingChat) return null;
    emit(state.copyWith(isCreatingChat: () => true));
    try {
      return await _repository.createDirectChat(userId);
    } catch (e, s) {
      if (isClosed) return null;
      getIt<Talker>().error('[chats] create chat failed', e, s);
      emit(
        state.copyWith(
          errorMessage: () => 'Не удалось создать чат. Попробуйте снова',
        ),
      );
      return null;
    } finally {
      if (!isClosed) emit(state.copyWith(isCreatingChat: () => false));
    }
  }

  void clearError() {
    emit(state.copyWith(errorMessage: () => null));
  }
}
