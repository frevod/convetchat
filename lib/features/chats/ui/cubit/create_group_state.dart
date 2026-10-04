import 'dart:typed_data';

import 'package:equatable/equatable.dart';

class const CreateGroupState({
  final String name = '',
  final bool isPublic = false,
  final bool showInDirectory = false,
  final String? avatarPath,
  final Uint8List? avatarBytes,
  final bool isCreating = false,
  final String? errorMessage,
  final String? createdRoomId,
}) extends Equatable {
  bool get canSubmit => !isCreating;

  CreateGroupState copyWith({
    String Function()? name,
    bool Function()? isPublic,
    bool Function()? showInDirectory,
    String? Function()? avatarPath,
    Uint8List? Function()? avatarBytes,
    bool Function()? isCreating,
    String? Function()? errorMessage,
    String? Function()? createdRoomId,
  }) {
    return CreateGroupState(
      name: name != null ? name() : this.name,
      isPublic: isPublic != null ? isPublic() : this.isPublic,
      showInDirectory: showInDirectory != null
          ? showInDirectory()
          : this.showInDirectory,
      avatarPath: avatarPath != null ? avatarPath() : this.avatarPath,
      avatarBytes: avatarBytes != null ? avatarBytes() : this.avatarBytes,
      isCreating: isCreating != null ? isCreating() : this.isCreating,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      createdRoomId: createdRoomId != null
          ? createdRoomId()
          : this.createdRoomId,
    );
  }

  @override
  List<Object?> get props => [
    name,
    isPublic,
    showInDirectory,
    avatarPath,
    avatarBytes,
    isCreating,
    errorMessage,
    createdRoomId,
  ];
}
