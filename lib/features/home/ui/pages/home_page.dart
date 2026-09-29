import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/platform_style.dart';
import 'package:convetchat/features/home/ui/pages/home_page_andr.dart';
import 'package:convetchat/features/home/ui/pages/home_page_cup.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

class const HomePage({
  super.key,
  required final StatefulNavigationShell navigationShell,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (getIt<PlatformStyle>().isCupertino) {
      return HomePageCup(navigationShell: navigationShell);
    }
    return HomePageAndr(navigationShell: navigationShell);
  }
}
