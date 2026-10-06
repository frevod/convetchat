import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/platform_style.dart';
import 'package:convetchat/features/chat/domain/entities/chat_message.dart';
import 'package:convetchat/features/chat/ui/widgets/media_message_andr.dart';
import 'package:convetchat/features/chat/ui/widgets/media_message_cup.dart';
import 'package:flutter/widgets.dart';

class const MediaMessage({
  required final ChatMessage message,
  final VoidCallback? onLinkTap,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (getIt<PlatformStyle>().isCupertino) {
      return MediaMessageCup(message: message, onLinkTap: onLinkTap);
    }
    return MediaMessageAndr(message: message, onLinkTap: onLinkTap);
  }
}
