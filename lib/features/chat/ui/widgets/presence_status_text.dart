import 'package:convetchat/features/chat/ui/cubit/chat_state.dart';
import 'package:flutter/widgets.dart';

String chatStatusText(ChatState state) => presenceStatusText(
  typingUsers: state.typingUsers,
  partnerUserId: state.partnerUserId,
  partnerOnline: state.partnerOnline,
  partnerLastActive: state.partnerLastActive,
);

String presenceStatusText({
  required List<({String id, String name})> typingUsers,
  required String? partnerUserId,
  required bool partnerOnline,
  required DateTime? partnerLastActive,
}) {
  final typing = typingUsers;
  if (typing.isNotEmpty) {
    if (partnerUserId != null) {
      return 'печатает…';
    }
    if (typing.length == 1) {
      return '${typing.first.name} печатает…';
    }
    if (typing.length == 2) {
      return '${typing[0].name} и ${typing[1].name} печатают…';
    }
    return '${typing.first.name} и ещё ${typing.length - 1} печатают…';
  }
  if (partnerUserId == null) return '';
  if (partnerOnline) return 'в сети';
  final lastActive = partnerLastActive;
  if (lastActive != null) return 'был(а) в сети ${_ago(lastActive)}';
  return '';
}

String _ago(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inSeconds < 60) return 'только что';
  if (diff.inMinutes < 60) return '${diff.inMinutes} мин назад';
  if (diff.inHours < 24) return '${diff.inHours} ч назад';
  if (diff.inDays == 1) return 'вчера';
  if (diff.inDays < 7) return '${diff.inDays} дн назад';
  final d = time.day.toString().padLeft(2, '0');
  final m = time.month.toString().padLeft(2, '0');
  return '$d.$m';
}

class const PresenceStatusText({
  super.key,
  required final ChatState state,
  final TextStyle? style,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final text = chatStatusText(state);
    if (text.isEmpty) return const SizedBox.shrink();
    return Text(text, maxLines: 1, overflow: .ellipsis, style: style);
  }
}
