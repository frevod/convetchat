import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/platform_style.dart';
import 'package:convetchat/features/welcome/ui/widgets/logo_andr.dart';
import 'package:convetchat/features/welcome/ui/widgets/logo_cup.dart';
import 'package:flutter/widgets.dart';

class const Logo({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (getIt<PlatformStyle>().isCupertino) {
      return const LogoCup();
    }
    return const LogoAndr();
  }
}
