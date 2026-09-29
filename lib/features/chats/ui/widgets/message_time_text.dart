String messageTimeText(DateTime? time) {
  if (time == null) return '';
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final messageDay = DateTime(time.year, time.month, time.day);
  final difference = today.difference(messageDay).inDays;

  if (difference == 0) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
  if (difference == 1) {
    return 'вчера';
  }
  final d = time.day.toString().padLeft(2, '0');
  final m = time.month.toString().padLeft(2, '0');
  if (time.year != now.year) {
    final y = time.year.toString();
    return '$d.$m.$y';
  }
  return '$d.$m';
}
