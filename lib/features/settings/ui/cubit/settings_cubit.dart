import 'dart:async';
import 'dart:io';

import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/firebase/telemetry_service.dart';
import 'package:convetchat/core/push/push_service.dart';
import 'package:convetchat/features/auth/domain/repositories/auth_repository.dart';
import 'package:convetchat/features/encryption/domain/repositories/encryption_repository.dart';
import 'package:convetchat/features/settings/ui/cubit/settings_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:matrix/matrix.dart';
import 'package:talker_flutter/talker_flutter.dart';

class SettingsCubit(
  final AuthRepository _authRepository,
  final EncryptionRepository _encryptionRepository,
) extends Cubit<SettingsState> {
  StreamSubscription? _pushRulesSub;

  this : super(const SettingsState()) {
    _restoreTelemetryConsent();
    _loadProfile();
    _checkBackup();
    _restoreNotificationSettings();
    _restoreExperimentalFlags();
  }

  void _restoreTelemetryConsent() {
    emit(
      state.copyWith(
        telemetryConsent: () => getIt<TelemetryService>().hasConsent,
      ),
    );
  }

  Future<void> _loadProfile() async {
    try {
      final client = getIt<Client>();
      final profile = await client.getUserProfile(client.userID!);
      if (isClosed) return;
      emit(
        state.copyWith(
          displayName: () => profile.displayname,
          avatarMxc: () => profile.avatarUrl?.toString(),
          userId: () => client.userID,
        ),
      );
    } catch (e, s) {
      getIt<Talker>().error('Не удалось загрузить профиль', e, s);
      try {
        emit(state.copyWith(userId: () => getIt<Client>().userID));
      } catch (_) {}
    }
  }

  Future<void> setTelemetryConsent(bool enabled) async {
    if (isClosed) return;
    emit(state.copyWith(telemetryConsent: () => enabled));
    await getIt<TelemetryService>().setConsent(enabled);
    if (isClosed) return;
    if (enabled) {
      getIt<TelemetryService>().logEvent('analytics_consent_granted');
    }
  }

  Future<void> _checkBackup() async {
    try {
      final identity = await _encryptionRepository.getIdentityState();
      if (isClosed) return;
      emit(
        state.copyWith(
          backupReady: () => identity.initialized && identity.connected,
        ),
      );
    } catch (e, s) {
      getIt<Talker>().error('Не удалось проверить состояние крипты', e, s);
    }
  }

  Future<void> logout() async {
    emit(state.copyWith(isLoggingOut: () => true));
    try {
      await getIt<PushService>().removePusher();
      await _authRepository.logout();
      if (isClosed) return;
      emit(state.copyWith(isLoggingOut: () => false, loggedOut: () => true));
    } catch (e, s) {
      if (isClosed) return;
      getIt<Talker>().error('Ошибка выхода', e, s);
      emit(
        state.copyWith(
          isLoggingOut: () => false,
          errorMessage: () => 'Не удалось выйти. Попробуйте снова',
        ),
      );
    }
  }

  Future<void> updateDisplayName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty || isClosed) return;
    emit(state.copyWith(profileSaving: () => true));
    try {
      final client = getIt<Client>();
      await client.setProfileField(client.userID!, 'displayname', {
        'displayname': trimmed,
      });
      if (isClosed) return;
      emit(
        state.copyWith(
          displayName: () => trimmed,
          profileSaving: () => false,
          errorMessage: () => null,
        ),
      );
    } catch (e, s) {
      if (isClosed) return;
      getIt<Talker>().error('Не удалось сохранить имя', e, s);
      emit(
        state.copyWith(
          profileSaving: () => false,
          errorMessage: () => 'Не удалось сохранить имя. Попробуйте снова',
        ),
      );
    }
  }

  Future<void> updateAvatar(String path, {required String name}) async {
    if (isClosed) return;
    emit(state.copyWith(profileSaving: () => true));
    try {
      final client = getIt<Client>();
      final bytes = await File(path).readAsBytes();
      final image = MatrixImageFile(bytes: bytes, name: name);
      final file =
          await image.generateThumbnail(
            dimension: 1024,
            nativeImplementations: client.nativeImplementations,
          ) ??
          image;
      final mxc = await client.uploadContent(
        file.bytes,
        filename: file.name,
        contentType: file.mimeType,
      );
      await client.setProfileField(client.userID!, 'avatar_url', {
        'avatar_url': mxc.toString(),
      });
      if (isClosed) return;
      emit(
        state.copyWith(
          avatarMxc: () => mxc.toString(),
          profileSaving: () => false,
          errorMessage: () => null,
        ),
      );
    } catch (e, s) {
      if (isClosed) return;
      getIt<Talker>().error('Не удалось сменить аватар', e, s);
      emit(
        state.copyWith(
          profileSaving: () => false,
          errorMessage: () => 'Не удалось сменить аватар. Попробуйте снова',
        ),
      );
    }
  }

  void clearError() {
    emit(state.copyWith(errorMessage: () => null));
  }

  void _restoreNotificationSettings() {
    _syncNotificationsFromPushRules();
    try {
      _pushRulesSub = getIt<Client>().onSync.stream
          .where(
            (s) => s.accountData?.any((a) => a.type == 'm.push_rules') ?? false,
          )
          .listen((_) => _syncNotificationsFromPushRules());
    } catch (_) {}
  }

  void _syncNotificationsFromPushRules() {
    if (isClosed) return;
    try {
      final muted = getIt<Client>().allPushNotificationsMuted;
      emit(state.copyWith(notificationsEnabled: () => !muted));
    } catch (_) {}
  }

  Future<void> toggleNotifications(bool enabled) async {
    if (isClosed) return;
    emit(state.copyWith(notificationsEnabled: () => enabled));

    try {
      await getIt<Client>().setMuteAllPushNotifications(!enabled);
      _syncNotificationsFromPushRules();
    } catch (e, s) {
      getIt<Talker>().error('[settings] Ошибка переключения уведомлений', e, s);
      _syncNotificationsFromPushRules();
    }
  }

  Future<void> _restoreExperimentalFlags() async {
    try {
      final enabled = await _encryptionRepository
          .isDehydratedDevicesEnabled();
      if (isClosed) return;
      emit(state.copyWith(dehydratedDevicesEnabled: () => enabled));
    } catch (e, s) {
      getIt<Talker>().error('[settings] Не удалось прочитать флаги', e, s);
    }
  }

  Future<void> setDehydratedDevicesEnabled(bool enabled) async {
    if (isClosed) return;
    emit(state.copyWith(dehydratedDevicesEnabled: () => enabled));
    try {
      await _encryptionRepository.setDehydratedDevicesEnabled(enabled);
    } catch (e, s) {
      getIt<Talker>().error('[settings] Ошибка переключения флага', e, s);
      if (isClosed) return;
      emit(
        state.copyWith(
          dehydratedDevicesEnabled: () => !enabled,
          errorMessage: () => 'Не удалось применить настройку',
        ),
      );
    }
  }

  @override
  Future<void> close() async {
    await _pushRulesSub?.cancel();
    return super.close();
  }
}
