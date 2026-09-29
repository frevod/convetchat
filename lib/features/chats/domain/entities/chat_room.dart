import 'package:equatable/equatable.dart';

class const ChatRoom({
  required final String id,
  required final String displayName,
  required final String lastMessage,
  required final DateTime? lastTime,
  required final int unreadCount,
  required final String? avatarMxc,
  required final bool isDirect,
  required final bool online,
}) extends Equatable {
  @override
  List<Object?> get props => [
    id,
    displayName,
    lastMessage,
    lastTime,
    unreadCount,
    avatarMxc,
    isDirect,
    online,
  ];
}
