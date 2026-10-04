import 'package:equatable/equatable.dart';

class const FeedbackState({
  final bool isSending = false,

  final bool sent = false,

  final String? errorMessage,
}) extends Equatable {
  FeedbackState copyWith({
    bool Function()? isSending,
    bool Function()? sent,
    String? Function()? errorMessage,
  }) {
    return FeedbackState(
      isSending: isSending != null ? isSending() : this.isSending,
      sent: sent != null ? sent() : this.sent,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [isSending, sent, errorMessage];
}
