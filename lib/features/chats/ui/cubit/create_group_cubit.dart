import 'dart:io';
import 'dart:typed_data';

import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/features/chats/domain/repositories/chats_repository.dart';
import 'package:convetchat/features/chats/ui/cubit/create_group_state.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talker_flutter/talker_flutter.dart';

class CreateGroupCubit(final ChatsRepository _repository)
    extends Cubit<CreateGroupState> {
  this : super(const CreateGroupState());

  final TextEditingController nameController = TextEditingController();

  @override
  Future<void> close() {
    nameController.dispose();
    return super.close();
  }

  void onNameChanged(String value) {
    emit(state.copyWith(name: () => value));
  }

  void setPublic(bool value) {
    emit(
      state.copyWith(
        isPublic: () => value,
        showInDirectory: value ? null : () => false,
      ),
    );
  }

  void setShowInDirectory(bool value) {
    if (!state.isPublic) return;
    emit(state.copyWith(showInDirectory: () => value));
  }

  void setAvatar(String path, Uint8List bytes) {
    emit(state.copyWith(avatarPath: () => path, avatarBytes: () => bytes));
  }

  Future<Uint8List?> readAvatarFile(String path) async {
    try {
      return await File(path).readAsBytes();
    } catch (e, s) {
      getIt<Talker>().error('Не удалось прочитать аватар группы', e, s);
      return null;
    }
  }

  Future<void> submit() async {
    if (state.isCreating) return;
    emit(
      state.copyWith(
        isCreating: () => true,
        errorMessage: () => null,
        createdRoomId: () => null,
      ),
    );
    try {
      final roomId = await _repository.createGroup(
        name: state.name.trim().isEmpty ? null : state.name.trim(),
        isPublic: state.isPublic,
        showInDirectory: state.isPublic && state.showInDirectory,
        avatarBytes: state.avatarBytes,
      );
      if (isClosed) return;
      emit(
        state.copyWith(isCreating: () => false, createdRoomId: () => roomId),
      );
    } catch (e, s) {
      getIt<Talker>().error('Не удалось создать группу', e, s);
      if (isClosed) return;
      emit(
        state.copyWith(
          isCreating: () => false,
          errorMessage: () => 'Не удалось создать группу. Попробуйте снова',
        ),
      );
    }
  }

  void clearError() {
    emit(state.copyWith(errorMessage: () => null));
  }

  void consumeCreated() {
    emit(state.copyWith(createdRoomId: () => null));
  }
}
