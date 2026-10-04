import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/platform_style.dart';
import 'package:convetchat/features/chat/ui/widgets/message_reply_quote_andr.dart';
import 'package:convetchat/features/chat/ui/widgets/message_reply_quote_cup.dart';
import 'package:flutter/widgets.dart';

class const MessageReplyQuote({
  super.key,
  required final String? senderName,
  required final String? body,
  required final bool isOwn,
  required final VoidCallback onTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (getIt<PlatformStyle>().isCupertino) {
      return MessageReplyQuoteCup(
        senderName: senderName,
        body: body,
        isOwn: isOwn,
        onTap: onTap,
      );
    }
    return MessageReplyQuoteAndr(
      senderName: senderName,
      body: body,
      isOwn: isOwn,
      onTap: onTap,
    );
  }
}
