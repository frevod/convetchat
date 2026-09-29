import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/platform_style.dart';
import 'package:convetchat/features/welcome/ui/pages/splash_page_andr.dart';
import 'package:convetchat/features/welcome/ui/pages/splash_page_cup.dart';
import 'package:flutter/widgets.dart';

class const SplashPage({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (getIt<PlatformStyle>().isCupertino) {
      return const SplashPageCup();
    }
    return const SplashPageAndr();
  }
}
