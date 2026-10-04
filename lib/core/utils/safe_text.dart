String sanitizeForText(String input) {
  if (input.isEmpty) return input;
  var hasSurrogate = false;
  final units = input.codeUnits;
  for (var i = 0; i < units.length; i++) {
    final u = units[i];
    if (u >= 0xD800 && u <= 0xDFFF) {
      hasSurrogate = true;
      break;
    }
  }
  if (!hasSurrogate) return input;

  final sb = StringBuffer();
  for (var i = 0; i < units.length; i++) {
    final u = units[i];
    if (u >= 0xD800 && u <= 0xDBFF) {
      if (i + 1 < units.length) {
        final next = units[i + 1];
        if (next >= 0xDC00 && next <= 0xDFFF) {
          sb.writeCharCode(u);
          sb.writeCharCode(next);
          i++;
          continue;
        }
      }
      sb.writeCharCode(0xFFFD);
    } else if (u >= 0xDC00 && u <= 0xDFFF) {
      sb.writeCharCode(0xFFFD);
    } else {
      sb.writeCharCode(u);
    }
  }
  return sb.toString();
}

String safeTruncate(String input, int limit, {String ellipsis = '…'}) {
  if (limit <= 0) return '';
  final clean = sanitizeForText(input);
  if (clean.runes.length <= limit) return clean;
  return '${String.fromCharCodes(clean.runes.take(limit))}$ellipsis';
}

String safeInitial(String name) {
  final clean = sanitizeForText(name.trim());
  if (clean.isEmpty) return '?';
  return String.fromCharCode(clean.runes.first).toUpperCase();
}
