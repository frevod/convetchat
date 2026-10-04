import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/platform_style.dart';
import 'package:convetchat/features/chat/ui/widgets/pinned_banner_andr.dart';
import 'package:convetchat/features/chat/ui/widgets/pinned_banner_cup.dart';
import 'package:flutter/widgets.dart';

class const PinnedBanner({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (getIt<PlatformStyle>().isCupertino) {
      return const PinnedBannerCup();
    }
    return const PinnedBannerAndr();
  }
}
