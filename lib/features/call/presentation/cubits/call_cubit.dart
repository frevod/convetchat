import 'dart:async';

import 'package:convetchat/core/di/locator.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../../domain/entities/call_exception.dart';
import '../../domain/entities/call_media.dart';
import '../../domain/entities/call_support.dart';
import '../../domain/repositories/call_repository.dart';
import '../../domain/usecases/answer_call_usecase.dart';
import '../../domain/usecases/check_call_support_usecase.dart';
import '../../domain/usecases/start_call_usecase.dart';
import 'call_state.dart';

class CallCubit(
  final CheckCallSupportUseCase _checkSupport,
  final StartCallUseCase _startCall,
  final AnswerCallUseCase _answerCall,
  final CallRepository _repository, {
  required final String roomId,
}) extends Cubit<CallState> {
  this : super(const CallInitial());

  CallHandle? _handle;
  StreamSubscription? _mediaSub;
  bool _muted = false;
  bool _speakerOn = false;
  bool _aborted = false;

  Future<void> start() => _run(_startCall.call);

  Future<void> answer() => _run(_answerCall.call);

  Future<void> _run(
    Future<CallHandle> Function(StartCallParams params) useCase,
  ) async {
    if (state is! CallInitial && state is! CallFailed) return;
    _aborted = false;
    emit(const CallChecking());
    final support = await _checkSupport();
    if (isClosed) return;
    if (!support.isSupported) {
      emit(CallFailed(support.failure ?? CallSupportFailure.voipUnavailable));
      return;
    }
    emit(CallConnecting(roomId: roomId));
    try {
      final handle = _handle = await useCase(StartCallParams(roomId: roomId));
      if (isClosed || _aborted) {
        await _repository.hangup(handle);
        _handle = null;
        if (!isClosed) emit(const CallEnded());
        return;
      }
      _mediaSub = _repository.mediaEvents(handle).listen(_onMedia);
      emit(CallWaiting(roomId: roomId));
    } on CallException catch (e) {
      if (isClosed) return;
      emit(CallFailed(e.failure));
    } catch (_) {
      if (isClosed) return;
      emit(const CallFailed(CallSupportFailure.voipUnavailable));
    }
  }

  void _onMedia(CallMediaEvent event) {
    if (isClosed) return;
    final handle = _handle;
    switch (event) {
      case CallMediaEvent.remoteJoined:
        if (handle != null) unawaited(_repository.setCallConnected(handle));
        emit(CallActive(roomId: roomId, isMuted: _muted, speakerOn: _speakerOn));
      case CallMediaEvent.remoteLeft:
        unawaited(hangup());
      case CallMediaEvent.e2eeFailed:
        if (state is CallActive) {
          getIt<Talker>().error('[call] e2ee error during active call');
          return;
        }
        emit(const CallFailed(CallSupportFailure.voipUnavailable));
    }
  }

  Future<void> toggleMute() async {
    final handle = _handle;
    if (handle == null) return;
    _muted = !_muted;
    await _repository.setMicrophoneMuted(handle, _muted);
    _emitActive();
  }

  Future<void> toggleSpeaker() async {
    final handle = _handle;
    if (handle == null) return;
    _speakerOn = !_speakerOn;
    await _repository.setSpeakerphone(_speakerOn);
    _emitActive();
  }

  void _emitActive() {
    if (isClosed || state is! CallActive) return;
    emit(CallActive(roomId: roomId, isMuted: _muted, speakerOn: _speakerOn));
  }

  Future<void> hangup() async {
    _aborted = true;
    await _mediaSub?.cancel();
    _mediaSub = null;
    final handle = _handle;
    _handle = null;
    if (handle != null) {
      await _repository.hangup(handle);
    }
    if (!isClosed) emit(const CallEnded());
  }

  @override
  Future<void> close() {
    final sub = _mediaSub;
    _mediaSub = null;
    final handle = _handle;
    _handle = null;
    if (sub == null && handle == null) return super.close();
    return Future.wait([
      if (sub != null) sub.cancel(),
      if (handle != null) _repository.hangup(handle),
    ]).then((_) => super.close());
  }
}
