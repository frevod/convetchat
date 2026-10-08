import 'package:convetchat/features/chat/domain/entities/room_info.dart';
import 'package:equatable/equatable.dart';

class const RoomInfoState({
  final RoomInfo? info,
  final List<RoomParticipant> knockRequests = const [],
  final String? actionUserId,
  final bool isLoading = true,
  final bool isLeaving = false,
  final bool isSaving = false,
  final bool left = false,
  final String? errorMessage,
}) extends Equatable {
  RoomInfoState copyWith({
    RoomInfo? Function()? info,
    List<RoomParticipant> Function()? knockRequests,
    String? Function()? actionUserId,
    bool Function()? isLoading,
    bool Function()? isLeaving,
    bool Function()? isSaving,
    bool Function()? left,
    String? Function()? errorMessage,
  }) {
    return RoomInfoState(
      info: info != null ? info() : this.info,
      knockRequests: knockRequests != null
          ? knockRequests()
          : this.knockRequests,
      actionUserId: actionUserId != null ? actionUserId() : this.actionUserId,
      isLoading: isLoading != null ? isLoading() : this.isLoading,
      isLeaving: isLeaving != null ? isLeaving() : this.isLeaving,
      isSaving: isSaving != null ? isSaving() : this.isSaving,
      left: left != null ? left() : this.left,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    info,
    knockRequests,
    actionUserId,
    isLoading,
    isLeaving,
    isSaving,
    left,
    errorMessage,
  ];
}
