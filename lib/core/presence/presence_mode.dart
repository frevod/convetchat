import 'package:matrix/matrix.dart';

enum PresenceMode() {
  online,
  busy,
  offline;

  PresenceType get presenceType => switch (this) {
    PresenceMode.online => PresenceType.online,
    PresenceMode.busy => PresenceType.unavailable,
    PresenceMode.offline => PresenceType.offline,
  };

  static PresenceMode fromName(String? name) {
    return PresenceMode.values.firstWhere(
      (mode) => mode.name == name,
      orElse: () => PresenceMode.online,
    );
  }
}
