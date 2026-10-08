enum RtcCallIntent() {
  audio,
  video,
}

class const RtcFocusPreferred({
  required final String type,
  required final String livekitServiceUrl,
  required final String livekitAlias,
}) {
  factory fromJson(Map<String, Object?> json) =>
      RtcFocusPreferred(
        type: json['type'] as String? ?? '',
        livekitServiceUrl: json['livekit_service_url'] as String? ?? '',
        livekitAlias: json['livekit_alias'] as String? ?? '',
      );

  Map<String, Object?> toJson() => {
    'type': type,
    'livekit_service_url': livekitServiceUrl,
    'livekit_alias': livekitAlias,
  };
}

class const RtcFocusActive({
  required final String type,
  required final String focusSelection,
}) {
  factory fromJson(Map<String, Object?> json) =>
      RtcFocusActive(
        type: json['type'] as String? ?? '',
        focusSelection: json['focus_selection'] as String? ?? '',
      );

  Map<String, Object?> toJson() => {
    'type': type,
    'focus_selection': focusSelection,
  };
}

class const RtcMember({
  required final String application,
  required final String callId,
  required final String? deviceId,
  required final DateTime? createdAt,
  required final Duration expires,
  required final List<RtcFocusPreferred> fociPreferred,
  required final RtcFocusActive? focusActive,
  required final RtcCallIntent callIntent,
  required final String? membershipId,
  required final String scope,
  required final String? senderId,
}) {
  static const String eventType = 'org.matrix.msc3401.call.member';
  static const Duration fallbackTtl = Duration(hours: 4);

  factory fromJson(
    Map<String, Object?> json, {
    required String? senderId,
  }) {
    final createdAtMs =
        json['created_ts'] as int? ?? json['created_at'] as int?;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final intentName = json['m.call.intent'] as String?;
    return RtcMember(
      application: json['application'] as String? ?? '',
      callId: json['call_id'] as String? ?? '',
      deviceId: json['device_id'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        createdAtMs ?? nowMs,
      ),
      expires: Duration(
        milliseconds:
            (json['expires'] as int?) ?? fallbackTtl.inMilliseconds,
      ),
      fociPreferred:
          (json['foci_preferred'] as List?)
              ?.whereType<Map>()
              .map((e) => RtcFocusPreferred.fromJson(Map<String, Object?>.from(e)))
              .toList() ??
          const [],
      focusActive: json['focus_active'] is Map
          ? RtcFocusActive.fromJson(
              Map<String, Object?>.from(json['focus_active'] as Map),
            )
          : null,
      callIntent: _intentFromName(intentName),
      membershipId: json['membershipID'] as String?,
      scope: json['scope'] as String? ?? 'm.room',
      senderId: senderId,
    );
  }

  Map<String, Object?> toJson() => {
    'application': application,
    'call_id': callId,
    if (deviceId != null) 'device_id': deviceId,
    'expires': expires.inMilliseconds,
    'foci_preferred': fociPreferred.map((f) => f.toJson()).toList(),
    if (focusActive != null) 'focus_active': focusActive!.toJson(),
    'm.call.intent': callIntent.name,
    if (membershipId != null) 'membershipID': membershipId,
    'scope': scope,
    if (createdAt != null) 'created_ts': createdAt!.millisecondsSinceEpoch,
    if (createdAt != null) 'created_at': createdAt!.millisecondsSinceEpoch,
  };

  bool isExpired(DateTime now) {
    final created = createdAt;
    if (created == null) return true;
    return created.add(expires).isBefore(now);
  }
}

RtcCallIntent _intentFromName(String? name) {
  for (final intent in RtcCallIntent.values) {
    if (intent.name == name) return intent;
  }
  return RtcCallIntent.video;
}
