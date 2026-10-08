import 'dart:async';

import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/features/chat/domain/entities/room_info.dart';
import 'package:convetchat/features/chat/domain/repositories/chat_repository.dart';
import 'package:convetchat/features/chat/ui/cubit/room_info_state.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talker_flutter/talker_flutter.dart';

class RoomInfoCubit(
  final ChatRepository _repository, {
  required final String roomId,
}) extends Cubit<RoomInfoState> {
  this : super(const RoomInfoState()) {
    _subscription = _repository.watchRoomInfo(roomId).listen((info) {
      if (isClosed) return;
      emit(state.copyWith(info: () => info, isLoading: () => false));
    });
    _knockSubscription = _repository.watchKnockRequests(roomId).listen((
      requests,
    ) {
      if (isClosed) return;
      emit(state.copyWith(knockRequests: () => requests));
    });
  }

  late final StreamSubscription<RoomInfo> _subscription;
  late final StreamSubscription<List<RoomParticipant>> _knockSubscription;

  @override
  Future<void> close() {
    unawaited(_subscription.cancel());
    unawaited(_knockSubscription.cancel());
    return super.close();
  }

  Future<void> copyRoomId() async {
    final id = state.info?.roomId ?? roomId;
    await Clipboard.setData(ClipboardData(text: id));
  }

  Future<void> leave() async {
    if (state.isLeaving) return;
    emit(state.copyWith(isLeaving: () => true, errorMessage: () => null));
    try {
      await _repository.leaveRoom(roomId);
      if (isClosed) return;
      emit(state.copyWith(isLeaving: () => false, left: () => true));
    } catch (e, s) {
      getIt<Talker>().error('[chat] leave room failed', e, s);
      if (isClosed) return;
      emit(
        state.copyWith(
          isLeaving: () => false,
          errorMessage: () => 'Не удалось покинуть. Попробуйте снова',
        ),
      );
    }
  }

  Future<void> acceptKnock(String userId) async {
    if (state.actionUserId != null || isClosed) return;
    emit(state.copyWith(actionUserId: () => userId, errorMessage: () => null));
    try {
      await _repository.acceptKnock(roomId: roomId, userId: userId);
      if (isClosed) return;
      emit(state.copyWith(actionUserId: () => null));
    } catch (e, s) {
      getIt<Talker>().error('[chat] accept knock failed', e, s);
      if (isClosed) return;
      emit(
        state.copyWith(
          actionUserId: () => null,
          errorMessage: () => 'Не удалось впустить. Попробуйте снова',
        ),
      );
    }
  }

  Future<void> rejectKnock(String userId) async {
    if (state.actionUserId != null || isClosed) return;
    emit(state.copyWith(actionUserId: () => userId, errorMessage: () => null));
    try {
      await _repository.rejectKnock(roomId: roomId, userId: userId);
      if (isClosed) return;
      emit(state.copyWith(actionUserId: () => null));
    } catch (e, s) {
      getIt<Talker>().error('[chat] reject knock failed', e, s);
      if (isClosed) return;
      emit(
        state.copyWith(
          actionUserId: () => null,
          errorMessage: () => 'Не удалось отклонить. Попробуйте снова',
        ),
      );
    }
  }

  Future<void> updateName(String name) =>
      _saveRoom((id) => _repository.updateRoomName(id, name));

  Future<void> updateTopic(String topic) =>
      _saveRoom((id) => _repository.updateRoomTopic(id, topic));

  Future<void> updateAvatar(String path, String name) =>
      _saveRoom((id) => _repository.updateRoomAvatar(id, path, name));

  Future<void> setJoinRule(String joinRule) =>
      _saveRoom((id) => _repository.setRoomJoinRule(id, joinRule));

  Future<void> _saveRoom(Future<void> Function(String roomId) save) async {
    if (state.isSaving || isClosed) return;
    emit(state.copyWith(isSaving: () => true, errorMessage: () => null));
    try {
      await save(roomId);
      if (isClosed) return;
      emit(state.copyWith(isSaving: () => false));
    } catch (e, s) {
      getIt<Talker>().error('[chat] save room failed', e, s);
      if (isClosed) return;
      emit(
        state.copyWith(
          isSaving: () => false,
          errorMessage: () => 'Не удалось сохранить. Попробуйте снова',
        ),
      );
    }
  }

  void clearError() {
    emit(state.copyWith(errorMessage: () => null));
  }
}
