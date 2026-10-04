import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/platform_style.dart';
import 'package:convetchat/features/auth/ui/widgets/server_continue_button_andr.dart';
import 'package:convetchat/features/auth/ui/widgets/server_continue_button_cup.dart';
import 'package:flutter/widgets.dart';

class const ServerContinueButton({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (getIt<PlatformStyle>().isCupertino) {
      return const ServerContinueButtonCup();
    }
    return const ServerContinueButtonAndr();
  }
}
