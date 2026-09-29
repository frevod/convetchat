import 'package:convetchat/features/chat/domain/entities/chat_message.dart';

bool areSameGroup(ChatMessage a, ChatMessage b) {
  if (a.isState || b.isState) return false;
  return a.senderId == b.senderId;
}
