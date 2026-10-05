import 'package:equatable/equatable.dart';

class const SettingsState({
  final bool isLoggingOut = false,

  final bool loggedOut = false,

  final bool? backupReady,

  final bool telemetryConsent = false,

  final String? displayName,

  final String? avatarMxc,

  final String? userId,
  final String? errorMessage,

  final bool notificationsEnabled = true,

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
    String? Function()? userId,
    String? Function()? errorMessage,
    bool Function()? notificationsEnabled,
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
      userId: userId != null ? userId() : this.userId,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      notificationsEnabled: notificationsEnabled != null
          ? notificationsEnabled()
          : this.notificationsEnabled,
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
    userId,
    errorMessage,
    notificationsEnabled,
    profileSaving,
    dehydratedDevicesEnabled,
  ];
}
