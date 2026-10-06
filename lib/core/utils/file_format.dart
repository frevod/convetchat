String formatFileSize(int? bytes) {
  if (bytes == null) return '—';
  if (bytes < 1024) return '$bytes Б';
  const units = ['КБ', 'МБ', 'ГБ'];
  var value = bytes / 1024.0;
  var unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  final text = value >= 100
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1).replaceAll('.', ',');
  return '$text ${units[unit]}';
}

String fileExtensionOf(String name) {
  final dot = name.lastIndexOf('.');
  if (dot < 0 || dot == name.length - 1) return '';
  return name.substring(dot + 1).toLowerCase();
}
