import 'package:equatable/equatable.dart';

class const RoomCallInfo({
  required final bool active,
  required final bool joined,
  required final String roomName,
}) extends Equatable {
  static const RoomCallInfo none = RoomCallInfo(
    active: false,
    joined: false,
    roomName: '',
  );

  bool get canJoin => active && !joined;

  @override
  List<Object?> get props => [active, joined, roomName];
}
