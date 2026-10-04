import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/platform_style.dart';
import 'package:convetchat/features/chat/domain/entities/chat_message.dart';
import 'package:convetchat/features/chat/ui/widgets/reply_widget_andr.dart';
import 'package:convetchat/features/chat/ui/widgets/reply_widget_cup.dart';
import 'package:flutter/widgets.dart';

class const ReplyWidget({
  super.key,
  required final ChatMessage reply,
  required final VoidCallback onCancel,
  required final VoidCallback onTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (getIt<PlatformStyle>().isCupertino) {
      return ReplyWidgetCup(reply: reply, onCancel: onCancel, onTap: onTap);
    }
    return ReplyWidgetAndr(reply: reply, onCancel: onCancel, onTap: onTap);
  }
}
