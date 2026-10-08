import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/platform_style.dart';
import 'package:convetchat/features/welcome/ui/widgets/welcome_actions_andr.dart';
import 'package:convetchat/features/welcome/ui/widgets/welcome_actions_cup.dart';
import 'package:flutter/widgets.dart';

class const WelcomeActions({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (getIt<PlatformStyle>().isCupertino) {
      return const WelcomeActionsCup();
    }
    return const WelcomeActionsAndr();
  }
}
