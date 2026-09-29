import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/platform_style.dart';
import 'package:convetchat/features/chat/ui/widgets/message_input_andr.dart';
import 'package:convetchat/features/chat/ui/widgets/message_input_cup.dart';
import 'package:flutter/widgets.dart';

class const MessageInput({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (getIt<PlatformStyle>().isCupertino) {
      return const MessageInputCup();
    }
    return const MessageInputAndr();
  }
}
