import 'package:shared_preferences/shared_preferences.dart';

class StorageQuotaStore {
  static const _key = 'storage_max_bytes';

  static const int unlimited = 0;

  static const int mb512 = 512 * 1024 * 1024;
  static const int gb1 = 1024 * 1024 * 1024;
  static const int gb2 = 2 * 1024 * 1024 * 1024;
  static const int gb5 = 5 * 1024 * 1024 * 1024;
  static const int gb10 = 10 * 1024 * 1024 * 1024;

  static const List<int> options = [
    unlimited,
    mb512,
    gb1,
    gb2,
    gb5,
    gb10,
  ];

  int? _cache;

  Future<int> getMaxBytes() async {
    final cached = _cache;
    if (cached != null) return cached;
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getInt(_key) ?? unlimited;
      _cache = value;
      return value;
    } catch (_) {
      return unlimited;
    }
  }

  Future<void> setMaxBytes(int bytes) async {
    _cache = bytes;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_key, bytes);
    } catch (_) {}
  }

  static String formatBytes(int bytes) {
    if (bytes <= 0) return '0 Б';
    if (bytes < 1024) return '$bytes Б';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} КБ';
    final mb = kb / 1024;
    if (mb < 1024) return '${mb.toStringAsFixed(1)} МБ';
    final gb = mb / 1024;
    return '${gb.toStringAsFixed(gb < 10 ? 1 : 0)} ГБ';
  }

  static String formatOption(int bytes) {
    if (bytes == unlimited) return 'Без лимита';
    return formatBytes(bytes);
  }
}
