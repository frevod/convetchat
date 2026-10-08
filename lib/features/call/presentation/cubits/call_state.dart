import 'package:equatable/equatable.dart';

import '../../domain/entities/call_support.dart';

sealed class const CallState() extends Equatable {
  @override
  List<Object?> get props => [];
}

final class const CallInitial() extends CallState;

final class const CallChecking() extends CallState;

final class const CallConnecting({required final String roomId})
    extends CallState {
  @override
  List<Object?> get props => [roomId];
}

final class const CallWaiting({required final String roomId}) extends CallState {
  @override
  List<Object?> get props => [roomId];
}

final class const CallActive({
  required final String roomId,
  required final bool isMuted,
  required final bool speakerOn,
}) extends CallState {
  @override
  List<Object?> get props => [roomId, isMuted, speakerOn];
}

final class const CallEnded() extends CallState;

final class const CallFailed(final CallSupportFailure failure)
    extends CallState {
  String message() => failure.message();

  @override
  List<Object?> get props => [failure];
}
