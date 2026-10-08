import 'package:equatable/equatable.dart';

class const RoomParticipant({
  required final String id,
  required final String displayName,
  final String? avatarMxc,
  final bool invited = false,
  final bool knocked = false,
}) extends Equatable {
  @override
  List<Object?> get props => [id, displayName, avatarMxc, invited, knocked];
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
  final int knockCount = 0,
  final String joinRule = 'invite',
  final bool canEditName = false,
  final bool canEditTopic = false,
  final bool canEditAvatar = false,
  final bool canInvite = false,
  final bool canChangeJoinRule = false,
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
    knockCount,
    joinRule,
    canEditName,
    canEditTopic,
    canEditAvatar,
    canInvite,
    canChangeJoinRule,
  ];
}
