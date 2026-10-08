import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/platform_style.dart';
import 'package:convetchat/features/chat/ui/pages/knock_requests_page_andr.dart';
import 'package:convetchat/features/chat/ui/pages/knock_requests_page_cup.dart';
import 'package:flutter/widgets.dart';

class const KnockRequestsPage({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (getIt<PlatformStyle>().isCupertino) {
      return const KnockRequestsPageCup();
    }
    return const KnockRequestsPageAndr();
  }
}
