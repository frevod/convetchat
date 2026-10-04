import 'package:equatable/equatable.dart';

class const PublicRoom({
  required final String roomId,
  required final String name,
  required final String topic,
  required final String? avatarMxc,
  required final int memberCount,
}) extends Equatable {
  @override
  List<Object?> get props => [roomId, name, topic, avatarMxc, memberCount];
}
