import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/platform_style.dart';
import 'package:convetchat/features/chat/ui/widgets/chat_message_list_andr.dart';
import 'package:convetchat/features/chat/ui/widgets/chat_message_list_cup.dart';
import 'package:flutter/widgets.dart';

class const ChatMessageList({
  super.key,
  final EdgeInsets padding = EdgeInsets.zero,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (getIt<PlatformStyle>().isCupertino) {
      return ChatMessageListCup(padding: padding);
    }
    return const ChatMessageListAndr();
  }
}
