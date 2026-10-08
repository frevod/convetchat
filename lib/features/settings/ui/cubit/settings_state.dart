import 'package:convetchat/features/chats/domain/entities/chat_room.dart';
import 'package:equatable/equatable.dart';

class const SettingsState({
  final bool isLoggingOut = false,

  final bool loggedOut = false,

  final bool? backupReady,

  final bool telemetryConsent = false,

  final String? displayName,

  final String? avatarMxc,

  final Map<String, String> customFields = const {},

  final Set<String> editableProfileFields = const {},

  final List<String>? addableProfileFields,

  final bool profileFieldsSupported = false,

  final String? userId,
  final String? errorMessage,

  final bool notificationsEnabled = true,

  final bool peopleEnabled = true,

  final bool groupsEnabled = true,

  final bool invitesEnabled = true,

  final bool invitesSupported = true,

  final bool contentPreview = true,

  final List<ChatRoom> notificationRooms = const [],

  final bool profileSaving = false,

  final bool? dehydratedDevicesEnabled,
}) extends Equatable {
  SettingsState copyWith({
    bool Function()? isLoggingOut,
    bool Function()? loggedOut,
    bool Function()? backupReady,
    bool Function()? telemetryConsent,
    String? Function()? displayName,
    String? Function()? avatarMxc,
    Map<String, String> Function()? customFields,
    Set<String> Function()? editableProfileFields,
    List<String>? Function()? addableProfileFields,
    bool Function()? profileFieldsSupported,
    String? Function()? userId,
    String? Function()? errorMessage,
    bool Function()? notificationsEnabled,
    bool Function()? peopleEnabled,
    bool Function()? groupsEnabled,
    bool Function()? invitesEnabled,
    bool Function()? invitesSupported,
    bool Function()? contentPreview,
    List<ChatRoom> Function()? notificationRooms,
    bool Function()? profileSaving,
    bool Function()? dehydratedDevicesEnabled,
  }) {
    return SettingsState(
      isLoggingOut: isLoggingOut != null ? isLoggingOut() : this.isLoggingOut,
      loggedOut: loggedOut != null ? loggedOut() : this.loggedOut,
      backupReady: backupReady != null ? backupReady() : this.backupReady,
      telemetryConsent: telemetryConsent != null
          ? telemetryConsent()
          : this.telemetryConsent,
      displayName: displayName != null ? displayName() : this.displayName,
      avatarMxc: avatarMxc != null ? avatarMxc() : this.avatarMxc,
      customFields: customFields != null ? customFields() : this.customFields,
      editableProfileFields: editableProfileFields != null
          ? editableProfileFields()
          : this.editableProfileFields,
      addableProfileFields: addableProfileFields != null
          ? addableProfileFields()
          : this.addableProfileFields,
      profileFieldsSupported: profileFieldsSupported != null
          ? profileFieldsSupported()
          : this.profileFieldsSupported,
      userId: userId != null ? userId() : this.userId,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      notificationsEnabled: notificationsEnabled != null
          ? notificationsEnabled()
          : this.notificationsEnabled,
      invitesEnabled: invitesEnabled != null
          ? invitesEnabled()
          : this.invitesEnabled,
      invitesSupported: invitesSupported != null
          ? invitesSupported()
          : this.invitesSupported,
      contentPreview: contentPreview != null
          ? contentPreview()
          : this.contentPreview,
      peopleEnabled: peopleEnabled != null
          ? peopleEnabled()
          : this.peopleEnabled,
      groupsEnabled: groupsEnabled != null
          ? groupsEnabled()
          : this.groupsEnabled,
      notificationRooms: notificationRooms != null
          ? notificationRooms()
          : this.notificationRooms,
      profileSaving: profileSaving != null
          ? profileSaving()
          : this.profileSaving,
      dehydratedDevicesEnabled: dehydratedDevicesEnabled != null
          ? dehydratedDevicesEnabled()
          : this.dehydratedDevicesEnabled,
    );
  }

  @override
  List<Object?> get props => [
    isLoggingOut,
    loggedOut,
    backupReady,
    telemetryConsent,
    displayName,
    avatarMxc,
    customFields,
    editableProfileFields,
    addableProfileFields,
    profileFieldsSupported,
    userId,
    errorMessage,
    notificationsEnabled,
    invitesEnabled,
    invitesSupported,
    contentPreview,
    peopleEnabled,
    groupsEnabled,
    notificationRooms,
    profileSaving,
    dehydratedDevicesEnabled,
  ];
}
