import 'package:convetchat/features/chats/domain/entities/notification_mode.dart';
import 'package:equatable/equatable.dart';

class const NotificationModeState({
  final NotificationMode mode = NotificationMode.all,
  final bool supported = false,
  final bool isLoading = true,
  final bool isSaving = false,
  final String? errorMessage,
}) extends Equatable {
  NotificationModeState copyWith({
    NotificationMode Function()? mode,
    bool Function()? supported,
    bool Function()? isLoading,
    bool Function()? isSaving,
    String? Function()? errorMessage,
  }) {
    return NotificationModeState(
      mode: mode != null ? mode() : this.mode,
      supported: supported != null ? supported() : this.supported,
      isLoading: isLoading != null ? isLoading() : this.isLoading,
      isSaving: isSaving != null ? isSaving() : this.isSaving,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    mode,
    supported,
    isLoading,
    isSaving,
    errorMessage,
  ];
}
