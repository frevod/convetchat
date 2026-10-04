import 'package:convetchat/core/utils/safe_text.dart';

export 'package:convetchat/core/utils/safe_text.dart'
    show sanitizeForText, safeTruncate, safeInitial;

String avatarInitial(String name) => safeInitial(name);

String messageClockText(DateTime time) {
  final h = time.hour.toString().padLeft(2, '0');
  final m = time.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

String mediaTimeText(Duration duration) {
  final total = duration.inSeconds;
  final m = total ~/ 60;
  final s = (total % 60).toString().padLeft(2, '0');
  return '$m:$s';
}
