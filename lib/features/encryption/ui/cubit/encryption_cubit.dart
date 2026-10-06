import 'dart:convert';

import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/features/encryption/domain/repositories/encryption_repository.dart';
import 'package:convetchat/features/encryption/ui/cubit/encryption_state.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:matrix/encryption.dart';
import 'package:talker_flutter/talker_flutter.dart';

class EncryptionCubit(
  final EncryptionRepository _repository, {
  required bool reset,
}) extends Cubit<EncryptionState> {
  this : super(EncryptionState(reset: reset)) {
    _init();
  }

  final TextEditingController keyController = TextEditingController();
  final TextEditingController newPassphraseController = TextEditingController();
  final TextEditingController repeatPassphraseController =
      TextEditingController();
  final ScrollController devicesScrollController = ScrollController();

  KeyVerification? _verification;

  KeyVerification? get verification => _verification;

  bool get supportsSecureStorage {
    switch (defaultTargetPlatform) {
      case .android || .iOS || .macOS || .windows || .linux:
        return true;
      case .fuchsia:
        return false;
    }
  }

  @override
  Future<void> close() {
    _cancelVerification();
    keyController.dispose();
    newPassphraseController.dispose();
    repeatPassphraseController.dispose();
    devicesScrollController.dispose();
    return super.close();
  }

  Future<void> _init() async {
    newPassphraseController.addListener(_checkPassphrase);
    repeatPassphraseController.addListener(_checkPassphrase);
    keyController.addListener(_checkKeyEntered);

    try {
      final identity = await _repository.getIdentityState();
      if (isClosed) return;
      if (identity.initialized) {
        if (identity.connected) {
          emit(state.copyWith(step: () => .done));
          return;
        }

        final devices = await _repository.getVerifiedDevices();
        if (isClosed) return;
        KeyVerificationState? verificationState;
        if (devices.isNotEmpty) {
          _verification = await _repository.startDeviceVerification();
          _verification?.onUpdate = _onVerificationUpdate;
          verificationState = _verification?.state;
        }
        String? secureKey;
        if (supportsSecureStorage) {
          secureKey = await _repository.readSecureKey();
        }
        if (isClosed) return;
        if (secureKey != null) keyController.text = secureKey;
        emit(
          state.copyWith(
            step: () => .restore,
            connectedDevices: () => devices,
            verificationState: () => verificationState,
          ),
        );
        return;
      }
      emit(state.copyWith(step: () => .setupPassphrase));
    } catch (e, s) {
      if (isClosed) return;
      getIt<Talker>().error('[e2ee:cubit] get identity state failed', e, s);
      emit(
        state.copyWith(
          errorMessage: () =>
              'Не удалось проверить шифрование. Попробуйте снова',
        ),
      );
    }
  }

  void _checkPassphrase() {
    final passphrase = newPassphraseController.text;
    emit(
      state.copyWith(
        checks: () => PassphraseChecks(
          equalsRepeat:
              passphrase.isNotEmpty &&
              passphrase == repeatPassphraseController.text,
          longEnough: passphrase.length >= 12,
          upperAndLowerCase:
              passphrase.contains(RegExp(r'[A-Z]')) &&
              passphrase.contains(RegExp(r'[a-z]')),
          specialCharacters: passphrase.contains(
            RegExp(r'[!@#$%^&*(),.?":{}|<>]'),
          ),
          numbers: passphrase.contains(RegExp(r'\d')),
        ),
      ),
    );
  }

  void _checkKeyEntered() {
    final entered = keyController.text.isNotEmpty;
    if (state.keyEntered != entered) {
      emit(state.copyWith(keyEntered: () => entered));
    }
  }

  Future<void> _onVerificationUpdate() async {
    if (isClosed) return;
    final verification = _verification;
    final vState = verification?.state;
    emit(state.copyWith(verificationState: () => vState));
    if (_verification?.state != .done) return;

    emit(state.copyWith(waitingForSecrets: () => true));
    var tries = 0;
    const max = 30;
    var connected = false;
    while (!connected) {
      if (tries >= max) break;
      await Future.delayed(const Duration(seconds: 1));
      if (isClosed) return;
      try {
        connected = (await _repository.getIdentityState()).connected;
      } catch (e, s) {
        getIt<Talker>().error('[e2ee:cubit] wait for secrets failed', e, s);
        break;
      }
      tries++;
    }
    if (isClosed) return;
    emit(
      state.copyWith(
        waitingForSecrets: () => !connected,
        noSecretsReceived: () => !connected,
      ),
    );
    if (connected) {
      try {
        await _repository.loadBackupKeys();
      } catch (e, s) {
        getIt<Talker>().error('[e2ee:cubit] loadBackupKeys failed', e, s);
      }
      if (isClosed) return;
      final identity = await _repository.getIdentityState();
      if (isClosed) return;
      if (identity.connected) emit(state.copyWith(step: () => .done));
    }
  }

  bool _retrying = false;

  Future<void> retryVerification() async {
    if (_retrying || isClosed) return;
    _retrying = true;
    try {
      emit(state.copyWith(noSecretsReceived: () => false));
      _cancelVerification();
      _verification = await _repository.startDeviceVerification();
      if (isClosed) return;
      _verification?.onUpdate = _onVerificationUpdate;
      emit(state.copyWith(verificationState: () => _verification?.state));
    } finally {
      _retrying = false;
    }
  }

  Future<void> setOrSkipPassphrase(String? passphrase) async {
    emit(state.copyWith(isLoading: () => true));
    try {
      final recoveryKey = await _repository.setupNewIdentity(
        passphrase: passphrase,
        reset: state.reset,
      );
      if (isClosed) return;
      emit(
        state.copyWith(
          isLoading: () => false,
          recoveryKey: () => recoveryKey,
          step: () => .showRecoveryKey,
        ),
      );
    } catch (e, s) {
      if (isClosed) return;
      getIt<Talker>().error('[e2ee:cubit] setup crypto identity failed', e, s);
      emit(
        state.copyWith(
          isLoading: () => false,
          errorMessage: () =>
              'Не удалось настроить шифрование. Попробуйте снова',
        ),
      );
    }
  }

  Future<void> unlock() async {
    final key = keyController.text.trim();
    if (key.isEmpty) return;
    _cancelVerification();
    emit(
      state.copyWith(
        unlockError: () => null,
        secretsMismatch: () => false,
        isLoading: () => true,
      ),
    );
    try {
      await _repository.restoreIdentity(key);
      if (isClosed) return;
      final identity = await _repository.getIdentityState();
      if (isClosed) return;
      if (identity.connected) {
        try {
          await _repository.loadBackupKeys();
        } catch (e, s) {
          getIt<Talker>().error('[e2ee:cubit] loadBackupKeys failed', e, s);
        }
        if (isClosed) return;
      }
      emit(
        state.copyWith(
          isLoading: () => false,
          step: () => identity.connected ? .done : .restore,
        ),
      );
    } catch (e, s) {
      if (isClosed) return;
      getIt<Talker>().error('[e2ee:cubit] unlock: restore failed', e, s);
      if (e is InvalidPassphraseException) {
        getIt<Talker>().warning(
          '[e2ee:cubit] unlock: InvalidPassphraseException (invalid key)',
        );
        await _repository.writeSecureKey(null);
        if (isClosed) return;
        emit(state.copyWith(isLoading: () => false, unlockError: () => e));
        return;
      }
      getIt<Talker>().error('[e2ee:cubit] SSSS secrets mismatch', e, s);
      emit(state.copyWith(isLoading: () => false, secretsMismatch: () => true));
    }
  }

  Future<void> openKeyFile() async {
    final files = await FilePicker.pickFiles(
      type: .custom,
      allowedExtensions: ['txt'],
    );
    final file = files.isEmpty ? null : files.first;
    if (file == null || isClosed) return;
    try {
      final bytes = await file.readAsBytes();
      keyController.text = utf8.decode(bytes, allowMalformed: true).trim();
    } catch (e, s) {
      if (isClosed) return;
      getIt<Talker>().error('[e2ee:cubit] read key file failed', e, s);
      emit(
        state.copyWith(errorMessage: () => 'Не удалось прочитать файл ключа'),
      );
      return;
    }
    await unlock();
  }

  Future<void> toggleKeyDownloaded(bool? downloaded) async {
    final key = state.recoveryKey;
    if (key == null) return;
    final uri = await FilePicker.saveFile(
      fileName:
          'ConvetChat-Recovery-Key-${DateTime.now().toIso8601String()}.txt',
      bytes: Uint8List.fromList(key.codeUnits),
    );
    if (uri == null || isClosed) return;
    emit(state.copyWith(keyDownloaded: () => downloaded == true));
  }

  Future<void> toggleKeyInSecureStorage(bool? stored) async {
    final key = state.recoveryKey;
    if (stored == true && key == null) return;
    try {
      await _repository.writeSecureKey(stored == true ? key : null);
    } catch (e, s) {
      getIt<Talker>().error('[e2ee:cubit] write secure key failed', e, s);
      return;
    }
    if (isClosed) return;
    emit(state.copyWith(keyInSecureStorage: () => stored == true));
  }

  void toggleObscureText() {
    emit(state.copyWith(obscureText: () => !state.obscureText));
  }

  void startReset() {
    emit(state.copyWith(reset: () => true, step: () => .setupPassphrase));
  }

  void clearError() {
    emit(state.copyWith(errorMessage: () => null));
  }

  bool _navigating = false;

  Future<void> finishAndGoChats() async {
    if (_navigating) return;
    _navigating = true;
    try {
      await _repository.requestMissingSessions();
    } catch (e, s) {
      getIt<Talker>().error('[e2ee:cubit] requestMissingSessions failed', e, s);
    }
    getIt<GoRouter>().go('/chats');
  }

  Future<void> skip() async {
    if (_navigating) return;
    _navigating = true;
    try {
      await _repository.requestMissingSessions();
    } catch (e, s) {
      getIt<Talker>().error('[e2ee:cubit] requestMissingSessions failed', e, s);
    }
    getIt<GoRouter>().go('/chats');
  }

  void _cancelVerification() {
    final verification = _verification;
    if (verification != null &&
        verification.state != .done &&
        verification.state != .error) {
      verification.cancel();
    }
    _verification = null;
  }
}
