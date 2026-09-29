import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/errors/auth_errors.dart';
import 'package:convetchat/core/push/push_service.dart';
import 'package:convetchat/features/auth/domain/repositories/auth_repository.dart';
import 'package:convetchat/features/auth/ui/bloc/auth_state.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talker_flutter/talker_flutter.dart';

class AuthCubit(final AuthRepository _authRepository) extends Cubit<AuthState> {
  this : super(const AuthInitial());

  final TextEditingController serverController = TextEditingController(
    text: 'matrix.org',
  );
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Future<void> close() {
    serverController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    return super.close();
  }

  void clearError() {
    if (state is AuthFailure) emit(AuthInitial());
  }

  Future<void> _refreshPusher() async {
    try {
      await getIt<PushService>().refreshPusher();
    } catch (e, s) {
      getIt<Talker>().error('[auth] Ошибка регистрации пушера', e, s);
    }
  }

  Future<void> verifyServer() async {
    final homeserver = serverController.text.trim();
    if (homeserver.isEmpty) return;
    emit(AuthServerVerifying());
    try {
      await _authRepository.checkHomeserver(homeserver);
      if (isClosed) return;
      if (await _authRepository.supportsSso()) {
        if (isClosed) return;
        emit(AuthSsoAvailable());
      } else {
        emit(AuthServerVerified());
      }
    } catch (e, s) {
      if (isClosed) return;
      getIt<Talker>().error('Ошибка проверки сервера', e, s);
      emit(AuthFailure(authErrorMessage(e, isLogin: false)));
    }
  }

  void usePasswordInstead() => emit(AuthServerVerified());

  Future<void> loginWithSso() async {
    emit(AuthSsoInProgress());
    try {
      await _authRepository.loginWithSso();
      await _refreshPusher();

      if (isClosed) return;
      emit(AuthAuthenticated());
    } catch (e, s) {
      if (isClosed) return;
      getIt<Talker>().error('Ошибка SSO входа', e, s);
      emit(AuthFailure(authErrorMessage(e, isLogin: false)));
    }
  }

  Future<void> login() async {
    final userId = usernameController.text.trim();
    final password = passwordController.text;
    if (userId.isEmpty || password.isEmpty) return;
    emit(AuthLoggingIn());
    try {
      await _authRepository.login(username: userId, password: password);
      await _refreshPusher();

      if (isClosed) return;
      emit(AuthAuthenticated());
    } catch (e, s) {
      if (isClosed) return;
      getIt<Talker>().error('Ошибка входа', e, s);
      emit(AuthFailure(authErrorMessage(e, isLogin: true), isLogin: true));
    }
  }
}
