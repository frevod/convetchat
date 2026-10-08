const mentionsOnlyRoomsKey = 'notifications.mentionsOnlyRooms';

bool mentionsUser({
  required Map<String, Object?> content,
  required String plainBody,
  required String userId,
  required String? displayName,
}) {
  final mentions = content['m.mentions'];
  if (mentions is Map<String, Object?>) {
    final userIds = mentions['user_ids'];
    if (userIds is List && userIds.contains(userId)) return true;
    if (mentions['room'] == true) return true;
  }
  final name = displayName?.trim() ?? '';
  if (name.isNotEmpty && plainBody.contains(name)) return true;
  return false;
}
