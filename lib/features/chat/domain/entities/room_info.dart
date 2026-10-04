import 'package:equatable/equatable.dart';

class const RoomParticipant({
  required final String id,
  required final String displayName,
  final String? avatarMxc,
  final bool invited = false,
}) extends Equatable {
  @override
  List<Object?> get props => [id, displayName, avatarMxc, invited];
}

class const RoomInfo({
  required final String roomId,
  required final String name,
  final String topic = '',
  final String? avatarMxc,
  final String? canonicalAlias,
  final bool encrypted = false,
  final bool isDirect = false,
  final List<RoomParticipant> members = const [],
}) extends Equatable {
  int get memberCount => members.length;

  @override
  List<Object?> get props => [
    roomId,
    name,
    topic,
    avatarMxc,
    canonicalAlias,
    encrypted,
    isDirect,
    members,
  ];
}
