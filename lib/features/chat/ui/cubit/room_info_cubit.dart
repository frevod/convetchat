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
  }

  late final StreamSubscription<RoomInfo> _subscription;

  @override
  Future<void> close() {
    unawaited(_subscription.cancel());
    return super.close();
  }

  Future<void> copyRoomId() async {
    final id = state.info?.roomId ?? roomId;
    await Clipboard.setData(ClipboardData(text: id));
  }

  Future<void> leave() async {
    if (state.isLeaving) return;
    emit(
      state.copyWith(isLeaving: () => true, errorMessage: () => null),
    );
    try {
      await _repository.leaveRoom(roomId);
      if (isClosed) return;
      emit(state.copyWith(isLeaving: () => false, left: () => true));
    } catch (e, s) {
      getIt<Talker>().error('Не удалось покинуть комнату', e, s);
      if (isClosed) return;
      emit(
        state.copyWith(
          isLeaving: () => false,
          errorMessage: () => 'Не удалось покинуть. Попробуйте снова',
        ),
      );
    }
  }

  void clearError() {
    emit(state.copyWith(errorMessage: () => null));
  }
}
