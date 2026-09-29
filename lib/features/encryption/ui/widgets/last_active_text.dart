String lastActiveText(DateTime lastActive) {
  final diff = DateTime.now().difference(lastActive);
  if (diff.inMinutes < 1) return 'был только что';
  if (diff.inMinutes < 60) {
    return 'был ${_plural(diff.inMinutes, 'минуту', 'минуты', 'минут')} назад';
  }
  if (diff.inHours < 24) {
    return 'был ${_plural(diff.inHours, 'час', 'часа', 'часов')} назад';
  }
  if (diff.inDays < 7) {
    return 'был ${_plural(diff.inDays, 'день', 'дня', 'дней')} назад';
  }
  final d = lastActive.day.toString().padLeft(2, '0');
  final m = lastActive.month.toString().padLeft(2, '0');
  return 'был $d.$m.${lastActive.year}';
}

String _plural(int n, String one, String few, String many) {
  final mod100 = n % 100;
  if (mod100 >= 11 && mod100 <= 19) return '$n $many';
  return switch (n % 10) {
    1 => '$n $one',
    2 || 3 || 4 => '$n $few',
    _ => '$n $many',
  };
}
