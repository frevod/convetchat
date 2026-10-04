import 'dart:async';

import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/features/chats/domain/repositories/chats_repository.dart';
import 'package:convetchat/features/chats/ui/cubit/user_search_state.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:talker_flutter/talker_flutter.dart';

class UserSearchCubit(final ChatsRepository _repository)
    extends Cubit<UserSearchState> {
  this : super(const UserSearchState());

  final TextEditingController searchController = TextEditingController();

  Timer? _debounce;

  static const _debounceDelay = Duration(milliseconds: 500);

  int _searchGeneration = 0;

  @override
  Future<void> close() {
    _debounce?.cancel();
    searchController.dispose();
    return super.close();
  }

  void onQueryChanged(String query) {
    _debounce?.cancel();

    _searchGeneration++;
    if (query.trim().isEmpty) {
      emit(state.copyWith(results: () => [], isSearching: () => false));
      return;
    }
    emit(state.copyWith(isSearching: () => true));
    _debounce = Timer(_debounceDelay, () => _search(query.trim()));
  }

  Future<void> _search(String query) async {
    final generation = ++_searchGeneration;
    try {
      final results = await _repository.searchUsers(query);
      if (isClosed || generation != _searchGeneration) return;
      emit(state.copyWith(results: () => results, isSearching: () => false));
    } catch (e, s) {
      if (isClosed || generation != _searchGeneration) return;
      getIt<Talker>().error('Поиск пользователей не удался', e, s);
      emit(
        state.copyWith(
          isSearching: () => false,
          errorMessage: () => 'Поиск не удался. Попробуйте снова',
        ),
      );
    }
  }

  Future<void> openDirectChat(BuildContext context, String userId) async {
    emit(state.copyWith(isCreating: () => true));
    try {
      final roomId = await _repository.createDirectChat(userId);
      if (!context.mounted) return;
      context.push('/chat/$roomId');
    } catch (e, s) {
      getIt<Talker>().error('Не удалось создать чат', e, s);
      emit(
        state.copyWith(
          errorMessage: () => 'Не удалось создать чат. Попробуйте снова',
        ),
      );
    } finally {
      if (!isClosed) emit(state.copyWith(isCreating: () => false));
    }
  }

  void clearError() {
    emit(state.copyWith(errorMessage: () => null));
  }
}
