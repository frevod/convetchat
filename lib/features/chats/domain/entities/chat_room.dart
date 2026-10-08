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
  final bool busy = false,
  final String? inviteReason,
  final bool isMuted = false,
  final bool isPinned = false,
}) extends Equatable {
  ChatRoom copyWith({
    String? id,
    String? displayName,
    String? lastMessage,
    DateTime? Function()? lastTime,
    int? unreadCount,
    String? Function()? avatarMxc,
    bool? isDirect,
    bool? online,
    bool? busy,
    String? Function()? inviteReason,
    bool? isMuted,
    bool? isPinned,
  }) {
    return ChatRoom(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      lastMessage: lastMessage ?? this.lastMessage,
      lastTime: lastTime != null ? lastTime() : this.lastTime,
      unreadCount: unreadCount ?? this.unreadCount,
      avatarMxc: avatarMxc != null ? avatarMxc() : this.avatarMxc,
      isDirect: isDirect ?? this.isDirect,
      online: online ?? this.online,
      busy: busy ?? this.busy,
      inviteReason: inviteReason != null ? inviteReason() : this.inviteReason,
      isMuted: isMuted ?? this.isMuted,
      isPinned: isPinned ?? this.isPinned,
    );
  }

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
    busy,
    inviteReason,
    isMuted,
    isPinned,
  ];
}
