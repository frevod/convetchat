import 'dart:async';

import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/matrix/matrix_call_failure.dart';
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
          rooms: () => [
            for (final room in snapshot.rooms)
              if (!_leaving.contains(room.id)) room,
          ],
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

  final Set<String> _leaving = {};

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
      final failure = e is MatrixCallFailure ? e : null;
      getIt<Talker>().error(
        'Не удалось принять приглашение${failure == null ? '' : ': $failure'}',
        e,
        s,
      );
      emit(
        state.copyWith(
          errorMessage: () =>
              failure?.userMessage ?? 'Не удалось принять приглашение',
        ),
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

  Future<void> toggleMute(ChatRoom room) async {
    final previous = state.rooms;
    emit(
      state.copyWith(
        rooms: () =>
            _withUpdatedRoom(room.id, (r) => r.copyWith(isMuted: !r.isMuted)),
      ),
    );
    try {
      await _repository.setMuted(room.id, !room.isMuted);
    } catch (e, s) {
      if (isClosed) return;
      getIt<Talker>().error('Не удалось изменить уведомления', e, s);
      emit(
        state.copyWith(
          rooms: () => previous,
          errorMessage: () => 'Не удалось изменить уведомления',
        ),
      );
    }
  }

  Future<void> togglePin(ChatRoom room) async {
    final previous = state.rooms;
    emit(
      state.copyWith(
        rooms: () => _sorted(
          _withUpdatedRoom(room.id, (r) => r.copyWith(isPinned: !r.isPinned)),
        ),
      ),
    );
    try {
      await _repository.setPinned(room.id, !room.isPinned);
    } catch (e, s) {
      if (isClosed) return;
      getIt<Talker>().error('Не удалось закрепить чат', e, s);
      emit(
        state.copyWith(
          rooms: () => previous,
          errorMessage: () => 'Не удалось закрепить чат',
        ),
      );
    }
  }

  Future<void> leaveRoom(ChatRoom room) async {
    final previous = state.rooms;
    _leaving.add(room.id);
    emit(
      state.copyWith(
        rooms: () => previous.where((r) => r.id != room.id).toList(),
      ),
    );
    try {
      await _repository.leaveRoom(room.id);
    } catch (e, s) {
      _leaving.remove(room.id);
      if (isClosed) return;
      getIt<Talker>().error('Не удалось покинуть комнату', e, s);
      emit(
        state.copyWith(
          rooms: () => previous,
          errorMessage: () => 'Не удалось покинуть комнату',
        ),
      );
    }
  }

  List<ChatRoom> _withUpdatedRoom(
    String roomId,
    ChatRoom Function(ChatRoom) update,
  ) {
    return [for (final r in state.rooms) r.id == roomId ? update(r) : r];
  }

  static List<ChatRoom> _sorted(List<ChatRoom> rooms) {
    final sorted = [...rooms];
    sorted.sort((a, b) {
      if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
      final at = a.lastTime;
      final bt = b.lastTime;
      if (at == null && bt == null) return 0;
      if (at == null) return 1;
      if (bt == null) return -1;
      return bt.compareTo(at);
    });
    return sorted;
  }
}
