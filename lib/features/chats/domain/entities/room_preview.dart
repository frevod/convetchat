import 'package:equatable/equatable.dart';

class const RoomPreview({
  required final String roomId,
  required final String name,
  required final String topic,
  required final String? avatarMxc,
  required final int memberCount,
  required final String joinRule,
  required final bool knocked,
}) extends Equatable {
  RoomPreview copyWith({bool Function()? knocked}) {
    return RoomPreview(
      roomId: roomId,
      name: name,
      topic: topic,
      avatarMxc: avatarMxc,
      memberCount: memberCount,
      joinRule: joinRule,
      knocked: knocked != null ? knocked() : this.knocked,
    );
  }

  @override
  List<Object?> get props => [
    roomId,
    name,
    topic,
    avatarMxc,
    memberCount,
    joinRule,
    knocked,
  ];
}
