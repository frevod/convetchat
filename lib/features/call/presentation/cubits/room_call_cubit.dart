import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/watch_room_call_usecase.dart';
import 'room_call_state.dart';

class RoomCallCubit(final WatchRoomCallUseCase _watch, {required final String roomId})
    extends Cubit<RoomCallState> {
  this : super(const RoomCallIdle());

  late final StreamSubscription _sub = _watch(roomId).listen((info) {
    if (!isClosed) emit(RoomCallLive(info));
  });

  @override
  Future<void> close() async {
    await _sub.cancel();
    return super.close();
  }
}
