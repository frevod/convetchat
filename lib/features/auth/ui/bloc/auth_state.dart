import 'package:equatable/equatable.dart';

sealed class const AuthState() extends Equatable {
  @override
  List<Object?> get props => [];
}

final class const AuthInitial() extends AuthState;

final class const AuthServerVerifying() extends AuthState;

final class const AuthSsoInProgress() extends AuthState;

final class const AuthSsoUnsupported() extends AuthState;

final class const AuthAuthenticated() extends AuthState;

final class const AuthFailure(final String message) extends AuthState {
  @override
  List<Object?> get props => [message];
}
