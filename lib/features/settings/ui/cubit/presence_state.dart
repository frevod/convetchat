import 'package:convetchat/core/presence/presence_mode.dart';
import 'package:equatable/equatable.dart';

class const PresenceState({
  final PresenceMode mode = PresenceMode.online,
  final bool supported = true,
  final bool isLoading = true,
  final bool isSaving = false,
  final String? errorMessage,
}) extends Equatable {
  PresenceState copyWith({
    PresenceMode Function()? mode,
    bool Function()? supported,
    bool Function()? isLoading,
    bool Function()? isSaving,
    String? Function()? errorMessage,
  }) {
    return PresenceState(
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
