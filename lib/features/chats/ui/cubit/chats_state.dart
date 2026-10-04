import 'package:convetchat/features/chats/domain/entities/chat_room.dart';
import 'package:convetchat/features/chats/domain/entities/connection_status.dart';
import 'package:equatable/equatable.dart';

class const ChatsState({
  final List<ChatRoom> rooms = const [],

  final List<ChatRoom> invites = const [],
  final bool isLoading = true,

  final bool synced = false,

  final ConnectionStatus connectionStatus = ConnectionStatus.connected,

  final String? actionInviteId,
  final String? errorMessage,
}) extends Equatable {
  ChatsState copyWith({
    List<ChatRoom> Function()? rooms,
    List<ChatRoom> Function()? invites,
    bool Function()? isLoading,
    bool Function()? synced,
    ConnectionStatus Function()? connectionStatus,
    String? Function()? actionInviteId,
    String? Function()? errorMessage,
  }) {
    return ChatsState(
      rooms: rooms != null ? rooms() : this.rooms,
      invites: invites != null ? invites() : this.invites,
      isLoading: isLoading != null ? isLoading() : this.isLoading,
      synced: synced != null ? synced() : this.synced,
      connectionStatus: connectionStatus != null
          ? connectionStatus()
          : this.connectionStatus,
      actionInviteId: actionInviteId != null
          ? actionInviteId()
          : this.actionInviteId,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    rooms,
    invites,
    isLoading,
    synced,
    connectionStatus,
    actionInviteId,
    errorMessage,
  ];
}
