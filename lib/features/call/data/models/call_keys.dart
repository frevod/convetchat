class const CallKeysEntry({
  required final int index,
  required final String key,
}) {
  factory fromJson(Map<String, Object?> json) =>
      CallKeysEntry(index: json['index'] as int, key: json['key'] as String);

  Map<String, Object?> toJson() => {'index': index, 'key': key};
}

class const CallKeysMember({
  required final String id,
  required final String claimedDeviceId,
}) {
  factory fromJson(Map<String, Object?> json) => CallKeysMember(
    id: json['id'] as String,
    claimedDeviceId: json['claimed_device_id'] as String,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'claimed_device_id': claimedDeviceId,
  };
}

class const CallKeysSession({
  required final String application,
  required final String callId,
  required final String scope,
}) {
  factory fromJson(Map<String, Object?> json) => CallKeysSession(
    application: json['application'] as String,
    callId: json['call_id'] as String,
    scope: json['scope'] as String,
  );

  Map<String, Object?> toJson() => {
    'application': application,
    'call_id': callId,
    'scope': scope,
  };
}

class const CallKeysContent({
  required final CallKeysEntry keys,
  required final CallKeysMember member,
  required final String roomId,
  required final CallKeysSession session,
  required final int? sentTs,
}) {
  static const String eventType = 'io.element.call.encryption_keys';

  factory fromJson(Map<String, Object?> json) => CallKeysContent(
    keys: CallKeysEntry.fromJson(
      Map<String, Object?>.from(json['keys'] as Map),
    ),
    member: CallKeysMember.fromJson(
      Map<String, Object?>.from(json['member'] as Map),
    ),
    roomId: json['room_id'] as String,
    session: CallKeysSession.fromJson(
      Map<String, Object?>.from(json['session'] as Map),
    ),
    sentTs: json['sent_ts'] as int?,
  );

  Map<String, Object?> toJson() => {
    'keys': keys.toJson(),
    'member': member.toJson(),
    'room_id': roomId,
    'session': session.toJson(),
    if (sentTs != null) 'sent_ts': sentTs,
  };
}
