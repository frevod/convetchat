import 'package:convetchat/features/encryption/domain/entities/verified_device.dart';
import 'package:equatable/equatable.dart';
import 'package:matrix/encryption.dart';

enum EncryptionStep() {
  loading,
  setupPassphrase,
  showRecoveryKey,
  restore,
  done,
}

class const PassphraseChecks({
  final bool equalsRepeat = false,
  final bool longEnough = false,
  final bool upperAndLowerCase = false,
  final bool specialCharacters = false,
  final bool numbers = false,
}) extends Equatable {
  bool get canCreate =>
      equalsRepeat &&
      longEnough &&
      upperAndLowerCase &&
      specialCharacters &&
      numbers;

  @override
  List<Object?> get props => [
    equalsRepeat,
    longEnough,
    upperAndLowerCase,
    specialCharacters,
    numbers,
  ];
}

class const EncryptionState({
  final EncryptionStep step = .loading,
  final bool isLoading = false,

  final String? recoveryKey,

  final Object? unlockError,

  final bool secretsMismatch = false,

  final String? errorMessage,
  final List<VerifiedDevice> connectedDevices = const [],
  final KeyVerificationState? verificationState,
  final bool obscureText = true,
  final bool waitingForSecrets = false,
  final bool noSecretsReceived = false,
  final PassphraseChecks checks = const PassphraseChecks(),
  final bool keyEntered = false,
  final bool keyDownloaded = false,
  final bool keyInSecureStorage = false,
  final bool reset = false,
}) extends Equatable {
  EncryptionState copyWith({
    EncryptionStep Function()? step,
    bool Function()? isLoading,
    String Function()? recoveryKey,
    Object? Function()? unlockError,
    bool Function()? secretsMismatch,
    String? Function()? errorMessage,
    List<VerifiedDevice> Function()? connectedDevices,
    KeyVerificationState? Function()? verificationState,
    bool Function()? obscureText,
    bool Function()? waitingForSecrets,
    bool Function()? noSecretsReceived,
    PassphraseChecks Function()? checks,
    bool Function()? keyEntered,
    bool Function()? keyDownloaded,
    bool Function()? keyInSecureStorage,
    bool Function()? reset,
  }) {
    return EncryptionState(
      step: step != null ? step() : this.step,
      isLoading: isLoading != null ? isLoading() : this.isLoading,
      recoveryKey: recoveryKey != null ? recoveryKey() : this.recoveryKey,
      unlockError: unlockError != null ? unlockError() : this.unlockError,
      secretsMismatch: secretsMismatch != null
          ? secretsMismatch()
          : this.secretsMismatch,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      connectedDevices: connectedDevices != null
          ? connectedDevices()
          : this.connectedDevices,
      verificationState: verificationState != null
          ? verificationState()
          : this.verificationState,
      obscureText: obscureText != null ? obscureText() : this.obscureText,
      waitingForSecrets: waitingForSecrets != null
          ? waitingForSecrets()
          : this.waitingForSecrets,
      noSecretsReceived: noSecretsReceived != null
          ? noSecretsReceived()
          : this.noSecretsReceived,
      checks: checks != null ? checks() : this.checks,
      keyEntered: keyEntered != null ? keyEntered() : this.keyEntered,
      keyDownloaded: keyDownloaded != null
          ? keyDownloaded()
          : this.keyDownloaded,
      keyInSecureStorage: keyInSecureStorage != null
          ? keyInSecureStorage()
          : this.keyInSecureStorage,
      reset: reset != null ? reset() : this.reset,
    );
  }

  @override
  List<Object?> get props => [
    step,
    isLoading,
    recoveryKey,
    unlockError,
    secretsMismatch,
    errorMessage,
    connectedDevices,
    verificationState,
    obscureText,
    waitingForSecrets,
    noSecretsReceived,
    checks,
    keyEntered,
    keyDownloaded,
    keyInSecureStorage,
    reset,
  ];
}
