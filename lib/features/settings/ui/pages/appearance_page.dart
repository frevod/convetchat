import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/platform_style.dart';
import 'package:convetchat/features/settings/ui/pages/appearance_page_andr.dart';
import 'package:convetchat/features/settings/ui/pages/appearance_page_cup.dart';
import 'package:flutter/widgets.dart';

class const AppearancePage({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return (getIt<PlatformStyle>().isCupertino)
        ? const AppearancePageCup()
        : const AppearancePageAndr();
  }
}
