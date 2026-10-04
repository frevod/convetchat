import 'package:convetchat/features/chat/domain/entities/room_info.dart';
import 'package:equatable/equatable.dart';

class const RoomInfoState({
  final RoomInfo? info,
  final bool isLoading = true,
  final bool isLeaving = false,
  final bool left = false,
  final String? errorMessage,
}) extends Equatable {
  RoomInfoState copyWith({
    RoomInfo? Function()? info,
    bool Function()? isLoading,
    bool Function()? isLeaving,
    bool Function()? left,
    String? Function()? errorMessage,
  }) {
    return RoomInfoState(
      info: info != null ? info() : this.info,
      isLoading: isLoading != null ? isLoading() : this.isLoading,
      isLeaving: isLeaving != null ? isLeaving() : this.isLeaving,
      left: left != null ? left() : this.left,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [info, isLoading, isLeaving, left, errorMessage];
}
