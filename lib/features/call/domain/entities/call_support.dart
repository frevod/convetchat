final class CallSupportResult {
  const new supported() : failure = null;

  const new unsupported(this.failure);

  final CallSupportFailure? failure;

  bool get isSupported => failure == null;
}

enum CallSupportFailure() {
  noRtcFocus,

  jwtUnreachable,

  microphonePermanentlyDenied,

  voipUnavailable,
}

extension CallSupportFailureX on CallSupportFailure {
  String message() {
    switch (this) {
      case .noRtcFocus:
        return 'Звонки не поддерживаются сервером';
      case .jwtUnreachable:
        return 'Сервис звонков недоступен, попробуйте позже';
      case .microphonePermanentlyDenied:
        return 'Разрешите доступ к микрофону в настройках';
      case .voipUnavailable:
        return 'Звонки недоступны, попробуйте позже';
    }
  }
}
