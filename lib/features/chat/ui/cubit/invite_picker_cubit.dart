import 'dart:async';

import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/features/chat/ui/cubit/invite_picker_state.dart';
import 'package:convetchat/features/chats/domain/repositories/chats_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talker_flutter/talker_flutter.dart';

class InvitePickerCubit(final ChatsRepository _repository)
    extends Cubit<InvitePickerState> {
  Timer? _debounce;

  static const _debounceDelay = Duration(milliseconds: 400);

  this : super(const InvitePickerState()) {
    _loadCandidates();
  }

  int _generation = 0;

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }

  Future<void> _loadCandidates() async {
    try {
      final candidates = await _repository.directChatPartners();
      if (isClosed) return;
      emit(state.copyWith(candidates: () => candidates));
    } catch (e, s) {
      getIt<Talker>().error('[chat] load invite candidates failed', e, s);
    }
  }

  void setQuery(String query) {
    if (query == state.query) return;
    _generation++;
    emit(state.copyWith(query: () => query, errorMessage: () => null));
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      _debounce?.cancel();
      emit(state.copyWith(results: () => [], isSearching: () => false));
      return;
    }
    emit(state.copyWith(isSearching: () => true));
    _debounce?.cancel();
    _debounce = Timer(_debounceDelay, () => _search(trimmed));
  }

  Future<void> _search(String query) async {
    final generation = ++_generation;
    try {
      final results = await _repository.searchUsers(query);
      if (isClosed || generation != _generation) return;
      emit(state.copyWith(results: () => results, isSearching: () => false));
    } catch (e, s) {
      if (isClosed || generation != _generation) return;
      getIt<Talker>().error('[chat] invite user search failed', e, s);
      emit(
        state.copyWith(
          isSearching: () => false,
          errorMessage: () => 'Поиск не удался. Попробуйте снова',
        ),
      );
    }
  }

  void toggle(String userId) {
    final selected = Set<String>.of(state.selected);
    if (selected.contains(userId)) {
      selected.remove(userId);
    } else {
      selected.add(userId);
    }
    emit(state.copyWith(selected: () => selected));
  }

  Future<bool> inviteAll(String roomId, String? reason) async {
    final targets = state.selected.toList();
    if (targets.isEmpty || state.isSending || isClosed) return false;
    emit(
      state.copyWith(
        isSending: () => true,
        sentCount: () => 0,
        failed: () => [],
        errorMessage: () => null,
      ),
    );
    var sent = 0;
    final failed = <String>[];
    for (final userId in targets) {
      try {
        await _repository.inviteUser(roomId, userId, reason: reason);
        sent++;
      } catch (e, s) {
        getIt<Talker>().error('[chat] invite failed: $userId', e, s);
        failed.add(userId);
      }
      if (isClosed) return false;
      emit(state.copyWith(sentCount: () => sent, failed: () => failed));
    }
    emit(state.copyWith(isSending: () => false));
    if (failed.isNotEmpty) {
      emit(
        state.copyWith(
          errorMessage: () => failed.length == targets.length
              ? 'Не удалось пригласить. Попробуйте снова'
              : 'Не всех удалось пригласить: ${failed.length}',
        ),
      );
    }
    return failed.isEmpty;
  }

  void clearError() {
    emit(state.copyWith(errorMessage: () => null));
  }

  static String? manualUserId(String query) {
    final trimmed = query.trim();
    if (!trimmed.startsWith('@') || !trimmed.contains(':')) return null;
    return trimmed;
  }
}
