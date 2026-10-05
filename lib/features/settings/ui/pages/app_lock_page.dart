import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/platform_style.dart';
import 'package:convetchat/features/settings/ui/pages/app_lock_page_andr.dart';
import 'package:convetchat/features/settings/ui/pages/app_lock_page_cup.dart';
import 'package:flutter/widgets.dart';

class const AppLockPage({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (getIt<PlatformStyle>().isCupertino) {
      return const AppLockPageCup();
    }
    return const AppLockPageAndr();
  }
}
