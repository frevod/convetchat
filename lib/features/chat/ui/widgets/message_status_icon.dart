import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/platform_style.dart';
import 'package:convetchat/features/chat/domain/entities/chat_message.dart';
import 'package:convetchat/features/chat/ui/widgets/message_status_icon_andr.dart';
import 'package:convetchat/features/chat/ui/widgets/message_status_icon_cup.dart';
import 'package:flutter/widgets.dart';

class const MessageStatusIcon({super.key, required final MessageStatus? status})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (status == null) return const SizedBox.shrink();
    if (getIt<PlatformStyle>().isCupertino) {
      return MessageStatusIconCup(status: status!);
    }
    return MessageStatusIconAndr(status: status!);
  }
}
