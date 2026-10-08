import 'dart:async';
import 'dart:io';

import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/firebase/telemetry_service.dart';
import 'package:convetchat/core/matrix/server_capabilities.dart';
import 'package:convetchat/core/push/push_service.dart';
import 'package:convetchat/features/auth/domain/repositories/auth_repository.dart';
import 'package:convetchat/features/chats/domain/entities/chat_room.dart';
import 'package:convetchat/features/chats/domain/repositories/chats_repository.dart';
import 'package:convetchat/features/encryption/domain/repositories/encryption_repository.dart';
import 'package:convetchat/features/settings/ui/cubit/settings_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:matrix/matrix.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talker_flutter/talker_flutter.dart';

class SettingsCubit(
  final AuthRepository _authRepository,
  final EncryptionRepository _encryptionRepository,
  final ChatsRepository _chatsRepository,
) extends Cubit<SettingsState> {
  StreamSubscription? _pushRulesSub;
  StreamSubscription? _roomsSub;

  static const _peoplePrefsKey = 'notifications.peopleEnabled';
  static const _groupsPrefsKey = 'notifications.groupsEnabled';
  static const _contentPreviewPrefsKey = 'notifications.contentPreview';

  this : super(const SettingsState()) {
    _restoreTelemetryConsent();
    _loadProfile();
    _checkBackup();
    _restoreNotificationSettings();
    _restoreCategoryPrefs();
    _watchNotificationRooms();
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
      Capabilities? capabilities;
      try {
        capabilities = await client.getCapabilities();
      } catch (_) {}
      if (isClosed) return;
      final fields = <String, String>{};
      profile.additionalProperties.forEach((key, value) {
        if (value is String && value.trim().isNotEmpty) {
          fields[key] = value;
        }
      });
      final editable = {
        for (final key in fields.keys)
          if (ServerCapabilities.canEditProfileField(capabilities, key)) key,
      };
      final allowed = capabilities?.mProfileFields?.allowed;
      final supported = ServerCapabilities.profileFieldsSupported(capabilities);
      final addable = !supported || allowed == null
          ? null
          : allowed.where((key) => !fields.containsKey(key)).toList();
      emit(
        state.copyWith(
          displayName: () => profile.displayname,
          avatarMxc: () => profile.avatarUrl?.toString(),
          userId: () => client.userID,
          customFields: () => fields,
          editableProfileFields: () => editable,
          addableProfileFields: () => addable,
          profileFieldsSupported: () => supported,
        ),
      );
    } catch (e, s) {
      getIt<Talker>().error('[settings] load profile failed', e, s);
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
      getIt<Talker>().error('[settings] check backup state failed', e, s);
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
      getIt<Talker>().error('[settings] logout failed', e, s);
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
      getIt<Talker>().error('[settings] save display name failed', e, s);
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
      getIt<Talker>().error('[settings] update avatar failed', e, s);
      emit(
        state.copyWith(
          profileSaving: () => false,
          errorMessage: () => 'Не удалось сменить аватар. Попробуйте снова',
        ),
      );
    }
  }

  bool _canWriteProfileField(String field) {
    if (state.editableProfileFields.contains(field)) return true;
    if (!state.profileFieldsSupported) return false;
    final addable = state.addableProfileFields;
    if (addable != null) return addable.contains(field);
    return ServerCapabilities.isValidProfileFieldKey(field);
  }

  Future<void> updateProfileField(String field, String value) async {
    if (isClosed || !_canWriteProfileField(field)) return;
    final trimmed = value.trim();
    emit(state.copyWith(profileSaving: () => true));
    try {
      final client = getIt<Client>();
      final userId = client.userID!;
      if (trimmed.isEmpty) {
        await client.deleteProfileField(userId, field);
      } else {
        await client.setProfileField(userId, field, {field: trimmed});
      }
      if (isClosed) return;
      final fields = Map<String, String>.of(state.customFields);
      if (trimmed.isEmpty) {
        fields.remove(field);
      } else {
        fields[field] = trimmed;
      }
      final editable = Set<String>.of(state.editableProfileFields);
      final addable = state.addableProfileFields?.toList();
      if (trimmed.isEmpty) {
        editable.remove(field);
      } else {
        editable.add(field);
        addable?.remove(field);
      }
      emit(
        state.copyWith(
          customFields: () => fields,
          editableProfileFields: () => editable,
          addableProfileFields: () => addable,
          profileSaving: () => false,
          errorMessage: () => null,
        ),
      );
    } catch (e, s) {
      if (isClosed) return;
      getIt<Talker>().error('[settings] save profile field failed', e, s);
      emit(
        state.copyWith(
          profileSaving: () => false,
          errorMessage: () => 'Не удалось сохранить. Попробуйте снова',
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
      final client = getIt<Client>();
      final muted = client.allPushNotificationsMuted;
      final ruleset = client.globalPushRules;
      emit(
        state.copyWith(
          notificationsEnabled: () => !muted,
          invitesEnabled: () => _invitesEnabled(ruleset),
          invitesSupported: () => _isRuleSupported(
            ruleset,
            PushRuleKind.override,
            ServerCapabilities.inviteRuleId,
            fallback: state.invitesSupported,
          ),
        ),
      );
      unawaited(_restoreMentionDefaults(client));
    } catch (_) {}
  }

  Future<void> _restoreMentionDefaults(Client client) async {
    const rules = ['.m.rule.contains_display_name', '.m.rule.is_user_mention'];
    final override = client.globalPushRules?.override;
    if (override == null) return;
    for (final rule in override) {
      if (!rules.contains(rule.ruleId) || rule.enabled) continue;
      try {
        await client.setPushRuleEnabled(
          PushRuleKind.override,
          rule.ruleId,
          true,
        );
      } catch (e, s) {
        getIt<Talker>().error('[settings] restore mention rule failed', e, s);
      }
    }
  }

  bool _isRuleSupported(
    PushRuleSet? ruleset,
    PushRuleKind kind,
    String ruleId, {
    required bool fallback,
  }) {
    if (ruleset == null) return fallback;
    return ServerCapabilities.findPushRule(ruleset, kind, ruleId) != null;
  }

  bool _invitesEnabled(PushRuleSet? ruleset) {
    final rule = ServerCapabilities.findPushRule(
      ruleset,
      PushRuleKind.override,
      ServerCapabilities.inviteRuleId,
    );
    if (rule == null) return state.invitesEnabled;
    return rule.enabled;
  }

  Future<void> toggleInvites(bool enabled) async {
    if (isClosed) return;
    final client = getIt<Client>();
    if (!_isRuleSupported(
      client.globalPushRules,
      PushRuleKind.override,
      ServerCapabilities.inviteRuleId,
      fallback: true,
    )) {
      emit(state.copyWith(invitesSupported: () => false));
      getIt<Talker>().warning(
        '[settings] invite rule missing on server, toggle ignored',
      );
      return;
    }
    final previous = state.invitesEnabled;
    emit(state.copyWith(invitesEnabled: () => enabled));
    try {
      await client.setPushRuleEnabled(
        PushRuleKind.override,
        ServerCapabilities.inviteRuleId,
        enabled,
      );
    } on MatrixException catch (e, s) {
      if (e.error == MatrixError.M_NOT_FOUND) {
        emit(
          state.copyWith(
            invitesEnabled: () => previous,
            invitesSupported: () => false,
          ),
        );
        getIt<Talker>().warning('[settings] invite rule not found on server');
      } else {
        emit(state.copyWith(invitesEnabled: () => previous));
        getIt<Talker>().error('[settings] toggle invite rule failed', e, s);
      }
    } catch (e, s) {
      emit(state.copyWith(invitesEnabled: () => previous));
      getIt<Talker>().error('[settings] toggle invite rule failed', e, s);
    }
    _syncNotificationsFromPushRules();
  }

  Future<void> toggleNotifications(bool enabled) async {
    if (isClosed) return;
    emit(state.copyWith(notificationsEnabled: () => enabled));

    try {
      await getIt<Client>().setMuteAllPushNotifications(!enabled);
      _syncNotificationsFromPushRules();
    } catch (e, s) {
      getIt<Talker>().error('[settings] toggle notifications failed', e, s);
      _syncNotificationsFromPushRules();
    }
  }

  Future<void> _restoreCategoryPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (isClosed) return;
      emit(
        state.copyWith(
          peopleEnabled: () => prefs.getBool(_peoplePrefsKey) ?? true,
          groupsEnabled: () => prefs.getBool(_groupsPrefsKey) ?? true,
          contentPreview: () => prefs.getBool(_contentPreviewPrefsKey) ?? true,
        ),
      );
    } catch (e, s) {
      getIt<Talker>().error('[settings] restore category prefs failed', e, s);
    }
  }

  void _watchNotificationRooms() {
    try {
      _roomsSub = _chatsRepository.watchRooms().listen((snapshot) {
        if (isClosed) return;
        emit(state.copyWith(notificationRooms: () => snapshot.rooms));
      });
    } catch (e, s) {
      getIt<Talker>().error('[settings] watch rooms failed', e, s);
    }
  }

  List<ChatRoom> categoryRooms(bool people) {
    return state.notificationRooms.where((r) => r.isDirect == people).toList();
  }

  List<ChatRoom> categoryExceptions(bool people) {
    final enabled = people ? state.peopleEnabled : state.groupsEnabled;
    return state.notificationRooms
        .where((r) => r.isDirect == people && r.isMuted == enabled)
        .toList();
  }

  Future<void> togglePeopleCategory(bool value) => _toggleCategory(true, value);

  Future<void> toggleContentPreview(bool value) async {
    if (isClosed) return;
    emit(state.copyWith(contentPreview: () => value));
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_contentPreviewPrefsKey, value);
    } catch (e, s) {
      getIt<Talker>().error('[settings] save content preview failed', e, s);
    }
  }

  Future<void> toggleGroupsCategory(bool value) =>
      _toggleCategory(false, value);

  Future<void> _toggleCategory(bool people, bool value) async {
    if (isClosed) return;
    final rooms = categoryRooms(people);
    final flipped = {for (final r in rooms) r.id: !r.isMuted};
    emit(
      state.copyWith(
        peopleEnabled: people ? () => value : null,
        groupsEnabled: people ? null : () => value,
        notificationRooms: () => [
          for (final r in state.notificationRooms)
            flipped.containsKey(r.id) ? r.copyWith(isMuted: flipped[r.id]) : r,
        ],
      ),
    );
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(people ? _peoplePrefsKey : _groupsPrefsKey, value);
    } catch (e, s) {
      getIt<Talker>().error('[settings] save category pref failed', e, s);
    }
    for (final entry in flipped.entries) {
      try {
        await _chatsRepository.setMuted(entry.key, entry.value);
      } catch (e, s) {
        getIt<Talker>().error('[settings] toggle category failed', e, s);
      }
    }
  }

  Future<void> removeException(ChatRoom room, bool people) async {
    if (isClosed) return;
    final enabled = people ? state.peopleEnabled : state.groupsEnabled;
    emit(
      state.copyWith(
        notificationRooms: () => [
          for (final r in state.notificationRooms)
            r.id == room.id ? r.copyWith(isMuted: !enabled) : r,
        ],
      ),
    );
    try {
      await _chatsRepository.setMuted(room.id, !enabled);
    } catch (e, s) {
      getIt<Talker>().error('[settings] remove exception failed', e, s);
    }
  }

  Future<void> _restoreExperimentalFlags() async {
    try {
      final enabled = await _encryptionRepository.isDehydratedDevicesEnabled();
      if (isClosed) return;
      emit(state.copyWith(dehydratedDevicesEnabled: () => enabled));
    } catch (e, s) {
      getIt<Talker>().error('[settings] read experimental flags failed', e, s);
    }
  }

  Future<void> setDehydratedDevicesEnabled(bool enabled) async {
    if (isClosed) return;
    emit(state.copyWith(dehydratedDevicesEnabled: () => enabled));
    try {
      await _encryptionRepository.setDehydratedDevicesEnabled(enabled);
    } catch (e, s) {
      getIt<Talker>().error('[settings] toggle experimental flag failed', e, s);
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
    await _roomsSub?.cancel();
    return super.close();
  }
}
