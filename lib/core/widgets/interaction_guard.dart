abstract final class InteractionGuard() {
  static DateTime? _lastMark;

  static void mark() {
    _lastMark = DateTime.now();
  }

  static bool consume() {
    final mark = _lastMark;
    _lastMark = null;
    if (mark == null) return false;
    return DateTime.now().difference(mark) < const Duration(seconds: 2);
  }
}
