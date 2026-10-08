import 'package:shared_preferences/shared_preferences.dart';

final class PendingAnswerStore() {
  static const String _roomKey = 'call_pending_answer_room';
  static const String _nameKey = 'call_pending_answer_name';
  static const String _tsKey = 'call_pending_answer_ts';
  static const Duration _maxAge = Duration(seconds: 90);

  Future<void> save(String roomId, String roomName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_roomKey, roomId);
    await prefs.setString(_nameKey, roomName);
    await prefs.setInt(_tsKey, DateTime.now().millisecondsSinceEpoch);
  }

  Future<({String roomId, String roomName})?> drain() async {
    final prefs = await SharedPreferences.getInstance();
    final roomId = prefs.getString(_roomKey);
    final roomName = prefs.getString(_nameKey) ?? '';
    final ts = prefs.getInt(_tsKey);
    await prefs.remove(_roomKey);
    await prefs.remove(_nameKey);
    await prefs.remove(_tsKey);
    if (roomId == null || ts == null) return null;
    final age = DateTime.now().difference(
      DateTime.fromMillisecondsSinceEpoch(ts),
    );
    if (age > _maxAge) return null;
    return (roomId: roomId, roomName: roomName);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_roomKey);
    await prefs.remove(_nameKey);
    await prefs.remove(_tsKey);
  }
}
