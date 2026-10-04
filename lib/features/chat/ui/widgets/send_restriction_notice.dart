import 'package:convetchat/features/chat/domain/entities/chat_send_restriction.dart';
import 'package:flutter/widgets.dart';

String sendRestrictionText(ChatSendRestriction restriction) {
  return switch (restriction) {
    ChatSendRestriction.none => '',
    ChatSendRestriction.invitePending =>
      'Приглашение ещё не принято — сообщения не отправляются',
    ChatSendRestriction.banned => 'Вы заблокированы в этом чате',
    ChatSendRestriction.left => 'Вы покинули этот чат',
    ChatSendRestriction.tombstoned => 'Чат закрыт',
    ChatSendRestriction.noPermission => 'У вас нет прав писать в этом чате',
    ChatSendRestriction.partnerUnavailable =>
      'Собеседник ещё не принял приглашение — сообщения не отправятся',
  };
}

class const SendRestrictionNotice({
  super.key,
  required final ChatSendRestriction restriction,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        child: Center(
          child: Text(
            sendRestrictionText(restriction),
            textAlign: .center,
            style: const TextStyle(fontSize: 13),
          ),
        ),
      ),
    );
  }
}
