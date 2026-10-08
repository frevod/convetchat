import 'dart:async';

import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/features/chats/domain/entities/chat_room.dart';
import 'package:convetchat/features/chats/domain/entities/notification_mode.dart';
import 'package:convetchat/features/chats/domain/repositories/chats_repository.dart';
import 'package:convetchat/features/chats/ui/cubit/notification_mode_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talker_flutter/talker_flutter.dart';

class NotificationModeCubit(
  final ChatsRepository _repository, {
  required final String roomId,
}) extends Cubit<NotificationModeState> {
  StreamSubscription<Set<String>>? _mentionsSubscription;
  StreamSubscription<({List<ChatRoom> rooms, List<ChatRoom> invites})>?
  _roomsSubscription;

  Set<String> _mentionIds = {};

  this : super(const NotificationModeState()) {
    _load();
    _mentionsSubscription = _repository.watchMentionsOnlyRooms().listen(
      _onMentionsChanged,
    );
    _roomsSubscription = _repository.watchRooms().listen(_onRoomsChanged);
  }

  Future<void> _onMentionsChanged(Set<String> ids) async {
    _mentionIds = ids;
    await _refresh();
  }

  Future<void> _onRoomsChanged(
    ({List<ChatRoom> rooms, List<ChatRoom> invites}) _,
  ) async {
    await _refresh();
  }

  Future<void> _refresh() async {
    if (isClosed) return;
    try {
      final mode = await _resolve();
      if (isClosed) return;
      emit(state.copyWith(mode: () => mode));
    } catch (_) {}
  }

  Future<NotificationMode> _resolve() async {
    if (await _repository.isRoomMuted(roomId)) {
      return NotificationMode.off;
    }
    return _mentionIds.contains(roomId)
        ? NotificationMode.mentions
        : NotificationMode.all;
  }

  Future<void> _load() async {
    try {
      final supported = await _repository.mentionsOnlySupported();
      if (isClosed) return;
      _mentionIds = await _repository.watchMentionsOnlyRooms().first;
      if (isClosed) return;
      final mode = await _resolve();
      if (isClosed) return;
      emit(
        state.copyWith(
          supported: () => supported,
          mode: () => mode,
          isLoading: () => false,
        ),
      );
    } catch (e, s) {
      getIt<Talker>().error('[chats] load notification mode failed', e, s);
      if (isClosed) return;
      emit(state.copyWith(isLoading: () => false));
    }
  }

  Future<void> setMode(NotificationMode mode) async {
    if (state.isSaving || state.mode == mode || isClosed) return;
    emit(state.copyWith(isSaving: () => true, errorMessage: () => null));
    try {
      if (mode == NotificationMode.off) {
        await _repository.setMuted(roomId, true);
        await _repository.setNotificationMode(roomId, NotificationMode.all);
      } else {
        await _repository.setMuted(roomId, false);
        await _repository.setNotificationMode(roomId, mode);
      }
      if (isClosed) return;
      emit(state.copyWith(mode: () => mode, isSaving: () => false));
    } catch (e, s) {
      if (isClosed) return;
      getIt<Talker>().error('[chats] save notification mode failed', e, s);
      final fallback = await _resolve();
      if (isClosed) return;
      emit(
        state.copyWith(
          mode: () => fallback,
          isSaving: () => false,
          errorMessage: () => 'Не удалось сохранить. Попробуйте снова',
        ),
      );
    }
  }

  void clearError() {
    emit(state.copyWith(errorMessage: () => null));
  }

  @override
  Future<void> close() async {
    await _mentionsSubscription?.cancel();
    await _roomsSubscription?.cancel();
    return super.close();
  }
}
