import 'dart:async';

import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/features/chats/domain/entities/chat_room.dart';
import 'package:convetchat/features/chats/domain/entities/connection_status.dart';
import 'package:convetchat/features/chats/domain/repositories/chats_repository.dart';
import 'package:convetchat/features/chats/ui/cubit/chats_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talker_flutter/talker_flutter.dart';

class ChatsCubit(final ChatsRepository _repository) extends Cubit<ChatsState> {
  this : super(const ChatsState()) {
    _subscription = _repository.watchRooms().listen((snapshot) {
      if (isClosed) return;
      emit(
        state.copyWith(
          rooms: () => snapshot.rooms,
          invites: () => snapshot.invites,
          isLoading: () => false,
        ),
      );
    });
    _connectionSubscription = _repository.watchConnectionStatus().listen((
      status,
    ) {
      if (isClosed) return;
      emit(state.copyWith(connectionStatus: () => status));
    });
    _repository.firstSync().then((_) {
      if (!isClosed) emit(state.copyWith(synced: () => true));
    });
  }

  late final StreamSubscription<
    ({List<ChatRoom> rooms, List<ChatRoom> invites})
  >
  _subscription;
  late final StreamSubscription<ConnectionStatus> _connectionSubscription;

  @override
  Future<void> close() {
    _subscription.cancel();
    _connectionSubscription.cancel();
    return super.close();
  }

  Future<void> acceptInvite(ChatRoom invite) async {
    if (state.actionInviteId != null) return;
    emit(state.copyWith(actionInviteId: () => invite.id));
    try {
      await _repository.acceptInvite(invite.id);
    } catch (e, s) {
      if (isClosed) return;
      getIt<Talker>().error('Не удалось принять приглашение', e, s);
      emit(
        state.copyWith(errorMessage: () => 'Не удалось принять приглашение'),
      );
    } finally {
      if (!isClosed) emit(state.copyWith(actionInviteId: () => null));
    }
  }

  Future<void> declineInvite(ChatRoom invite) async {
    if (state.actionInviteId != null) return;
    emit(state.copyWith(actionInviteId: () => invite.id));
    try {
      await _repository.declineInvite(invite.id);
    } catch (e, s) {
      if (isClosed) return;
      getIt<Talker>().error('Не удалось отклонить приглашение', e, s);
      emit(
        state.copyWith(errorMessage: () => 'Не удалось отклонить приглашение'),
      );
    } finally {
      if (!isClosed) emit(state.copyWith(actionInviteId: () => null));
    }
  }

  void clearError() {
    emit(state.copyWith(errorMessage: () => null));
  }
}
