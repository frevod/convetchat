import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/platform_style.dart';
import 'package:convetchat/features/chat/domain/entities/chat_message.dart';
import 'package:convetchat/features/chat/ui/widgets/state_message_andr.dart';
import 'package:convetchat/features/chat/ui/widgets/state_message_cup.dart';
import 'package:flutter/widgets.dart';

class const StateMessage({
  super.key,
  required final ChatMessage message,
  final bool isCollapsed = false,
  final bool expanded = false,
  final VoidCallback? onExpand,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (getIt<PlatformStyle>().isCupertino) {
      return StateMessageCup(
        message: message,
        isCollapsed: isCollapsed,
        expanded: expanded,
        onExpand: onExpand,
      );
    }
    return StateMessageAndr(
      message: message,
      isCollapsed: isCollapsed,
      expanded: expanded,
      onExpand: onExpand,
    );
  }
}
