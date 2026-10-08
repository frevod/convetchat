import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/matrix/server_capabilities.dart';
import 'package:convetchat/features/chats/domain/entities/public_room.dart';
import 'package:convetchat/features/chats/domain/entities/room_preview.dart';
import 'package:convetchat/features/chats/domain/repositories/chats_repository.dart';
import 'package:convetchat/features/chats/ui/cubit/room_preview_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:matrix/matrix.dart';
import 'package:talker_flutter/talker_flutter.dart';

class RoomPreviewCubit(
  final ChatsRepository _repository, {
  final Future<bool> Function()? summarySupported,
}) extends Cubit<RoomPreviewState> {
  this : super(const RoomPreviewState());

  Future<void> load(String roomIdOrAlias, {PublicRoom? fallback}) async {
    if (isClosed) return;
    emit(state.copyWith(isLoading: () => true, errorMessage: () => null));
    try {
      final check = summarySupported;
      final supported = check != null
          ? await check()
          : await ServerCapabilities.roomSummarySupported(getIt<Client>());
      if (isClosed) return;
      if (supported) {
        final preview = await _repository.fetchRoomPreview(roomIdOrAlias);
        if (isClosed) return;
        emit(state.copyWith(preview: () => preview, isLoading: () => false));
        return;
      }
      final fallbackRoom = fallback;
      if (fallbackRoom != null) {
        emit(
          state.copyWith(
            preview: () => RoomPreview(
              roomId: fallbackRoom.roomId,
              name: fallbackRoom.name,
              topic: fallbackRoom.topic,
              avatarMxc: fallbackRoom.avatarMxc,
              memberCount: fallbackRoom.memberCount,
              joinRule: fallbackRoom.joinRule,
              knocked: false,
            ),
            isLoading: () => false,
          ),
        );
        return;
      }
      emit(
        state.copyWith(
          isLoading: () => false,
          errorMessage: () => 'Предпросмотр недоступен на этом сервере',
        ),
      );
    } catch (e, s) {
      if (isClosed) return;
      getIt<Talker>().error('[chats] load room preview failed', e, s);
      emit(
        state.copyWith(
          isLoading: () => false,
          errorMessage: () => _previewErrorMessage(e),
        ),
      );
    }
  }

  Future<String?> join() async {
    final preview = state.preview;
    if (preview == null || state.isBusy || isClosed) return null;
    emit(state.copyWith(isBusy: () => true, errorMessage: () => null));
    try {
      final roomId = await _repository.joinRoom(preview.roomId);
      if (isClosed) return null;
      emit(state.copyWith(isBusy: () => false));
      return roomId;
    } catch (e, s) {
      if (isClosed) return null;
      getIt<Talker>().error('[chats] preview join failed', e, s);
      emit(
        state.copyWith(
          isBusy: () => false,
          errorMessage: () => _actionErrorMessage(e, 'Войти не удалось'),
        ),
      );
      return null;
    }
  }

  Future<void> knock() async {
    final preview = state.preview;
    if (preview == null || state.isBusy || isClosed) return;
    emit(state.copyWith(isBusy: () => true, errorMessage: () => null));
    try {
      await _repository.knockRoom(preview.roomId);
      if (isClosed) return;
      emit(
        state.copyWith(
          isBusy: () => false,
          preview: () => preview.copyWith(knocked: () => true),
        ),
      );
    } catch (e, s) {
      if (isClosed) return;
      getIt<Talker>().error('[chats] knock failed', e, s);
      emit(
        state.copyWith(
          isBusy: () => false,
          errorMessage: () => _actionErrorMessage(e, 'Постучаться не удалось'),
        ),
      );
    }
  }

  Future<void> cancelKnock() async {
    final preview = state.preview;
    if (preview == null || state.isBusy || isClosed) return;
    emit(state.copyWith(isBusy: () => true, errorMessage: () => null));
    try {
      await _repository.cancelKnock(preview.roomId);
      if (isClosed) return;
      emit(
        state.copyWith(
          isBusy: () => false,
          preview: () => preview.copyWith(knocked: () => false),
        ),
      );
    } catch (e, s) {
      if (isClosed) return;
      getIt<Talker>().error('[chats] cancel knock failed', e, s);
      emit(
        state.copyWith(
          isBusy: () => false,
          errorMessage: () => _actionErrorMessage(e, 'Отменить не удалось'),
        ),
      );
    }
  }

  void clearError() {
    emit(state.copyWith(errorMessage: () => null));
  }

  static String _previewErrorMessage(Object e) {
    if (e is MatrixException && e.error == MatrixError.M_NOT_FOUND) {
      return 'Комната не найдена';
    }
    if (e is MatrixException && e.error == MatrixError.M_FORBIDDEN) {
      return 'Нет доступа к этой комнате';
    }
    return 'Не удалось загрузить комнату. Попробуйте снова';
  }

  static String _actionErrorMessage(Object e, String fallback) {
    if (e is MatrixException && e.error == MatrixError.M_FORBIDDEN) {
      return 'Сервер отклонил запрос';
    }
    return fallback;
  }
}
