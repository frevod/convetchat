import 'package:convetchat/features/chats/domain/entities/room_preview.dart';
import 'package:equatable/equatable.dart';

class const RoomPreviewState({
  final RoomPreview? preview,
  final bool isLoading = false,
  final bool isBusy = false,
  final String? errorMessage,
}) extends Equatable {
  RoomPreviewState copyWith({
    RoomPreview? Function()? preview,
    bool Function()? isLoading,
    bool Function()? isBusy,
    String? Function()? errorMessage,
  }) {
    return RoomPreviewState(
      preview: preview != null ? preview() : this.preview,
      isLoading: isLoading != null ? isLoading() : this.isLoading,
      isBusy: isBusy != null ? isBusy() : this.isBusy,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [preview, isLoading, isBusy, errorMessage];
}
