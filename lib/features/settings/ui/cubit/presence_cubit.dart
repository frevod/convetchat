import 'dart:async';

import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/presence/presence_mode.dart';
import 'package:convetchat/features/settings/domain/repositories/presence_repository.dart';
import 'package:convetchat/features/settings/ui/cubit/presence_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:matrix/matrix.dart';
import 'package:talker_flutter/talker_flutter.dart';

class PresenceCubit(final PresenceRepository _repository)
    extends Cubit<PresenceState> {
  StreamSubscription<PresenceMode>? _subscription;

  this : super(const PresenceState()) {
    _load();
    _subscription = _repository.watchOwnMode().listen((mode) {
      if (isClosed) return;
      emit(state.copyWith(mode: () => mode));
    });
  }

  Future<void> _load() async {
    try {
      final supported = await _repository.busySupported() ?? true;
      if (isClosed) return;
      final mode = await _repository.ownMode();
      if (isClosed) return;
      emit(
        state.copyWith(
          supported: () => supported,
          mode: () => mode,
          isLoading: () => false,
        ),
      );
    } catch (e, s) {
      getIt<Talker>().error('[settings] load presence failed', e, s);
      if (isClosed) return;
      emit(state.copyWith(isLoading: () => false));
    }
  }

  Future<void> setMode(PresenceMode mode) async {
    if (state.isSaving || state.mode == mode || isClosed) return;
    final previous = state.mode;
    emit(state.copyWith(isSaving: () => true, errorMessage: () => null));
    try {
      await _repository.setOwnMode(mode);
      if (isClosed) return;
      emit(state.copyWith(mode: () => mode, isSaving: () => false));
    } on MatrixException catch (e, s) {
      if (isClosed) return;
      if (e.error == MatrixError.M_UNRECOGNIZED) {
        emit(
          state.copyWith(
            mode: () => previous,
            supported: () => false,
            isSaving: () => false,
          ),
        );
        getIt<Talker>().warning('[settings] presence mode not recognized');
      } else {
        emit(
          state.copyWith(
            mode: () => previous,
            isSaving: () => false,
            errorMessage: () => _rateLimitMessage(e),
          ),
        );
        getIt<Talker>().error('[settings] set presence failed', e, s);
      }
    } catch (e, s) {
      if (isClosed) return;
      getIt<Talker>().error('[settings] set presence failed', e, s);
      emit(
        state.copyWith(
          mode: () => previous,
          isSaving: () => false,
          errorMessage: () => 'Не удалось сменить статус. Попробуйте снова',
        ),
      );
    }
  }

  void clearError() {
    emit(state.copyWith(errorMessage: () => null));
  }

  static String _rateLimitMessage(MatrixException e) {
    if (e.error != MatrixError.M_LIMIT_EXCEEDED) {
      return 'Не удалось сменить статус. Попробуйте снова';
    }
    final retryMs = e.retryAfterMs;
    if (retryMs == null) return 'Слишком часто. Попробуйте позже';
    final seconds = (retryMs / 1000).ceil();
    return 'Слишком часто. Попробуйте через $seconds с';
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
