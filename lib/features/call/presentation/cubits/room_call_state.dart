import 'package:equatable/equatable.dart';

import '../../domain/entities/room_call_info.dart';

sealed class const RoomCallState() extends Equatable {
  @override
  List<Object?> get props => [];
}

final class const RoomCallIdle() extends RoomCallState;

final class const RoomCallLive(final RoomCallInfo info) extends RoomCallState {
  @override
  List<Object?> get props => [info];
}
