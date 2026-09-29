import 'package:equatable/equatable.dart';

sealed class const AuthState() extends Equatable {
  @override
  List<Object?> get props => [];
}

final class const AuthInitial() extends AuthState;

final class const AuthServerVerifying() extends AuthState;

final class const AuthServerVerified() extends AuthState;

final class const AuthSsoAvailable() extends AuthState;

final class const AuthSsoInProgress() extends AuthState;

final class const AuthLoggingIn() extends AuthState;

final class const AuthAuthenticated() extends AuthState;

final class const AuthFailure(
  final String message, {
  final bool isLogin = false,
}) extends AuthState {
  @override
  List<Object?> get props => [message, isLogin];
}
