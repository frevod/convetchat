import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/errors/auth_errors.dart';
import 'package:convetchat/core/push/push_service.dart';
import 'package:convetchat/features/auth/domain/exceptions/sso_cancelled_exception.dart';
import 'package:convetchat/features/auth/domain/repositories/auth_repository.dart';
import 'package:convetchat/features/auth/ui/bloc/auth_state.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talker_flutter/talker_flutter.dart';

class AuthCubit(final AuthRepository _authRepository) extends Cubit<AuthState> {
  this : super(const AuthInitial());

  final TextEditingController serverController = TextEditingController(
    text: 'convet.xyz',
  );

  @override
  Future<void> close() {
    serverController.dispose();
    return super.close();
  }

  void clearError() {
    if (state is AuthFailure) emit(AuthInitial());
  }

  void dismissSsoUnsupported() {
    if (state is AuthSsoUnsupported) emit(AuthInitial());
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

      emit(AuthSsoInProgress());
      await _authRepository.loginWithSso();
      await _refreshPusher();

      if (isClosed) return;
      emit(AuthAuthenticated());
    } on SsoNotSupportedException {
      if (isClosed) return;
      emit(AuthSsoUnsupported());
    } catch (e, s) {
      if (isClosed) return;
      getIt<Talker>().error('[auth] Ошибка входа через сайт', e, s);
      emit(AuthFailure(authErrorMessage(e)));
    }
  }
}
