import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/platform_style.dart';
import 'package:convetchat/features/encryption/ui/widgets/restore_bootstrap_view_andr.dart';
import 'package:convetchat/features/encryption/ui/widgets/restore_bootstrap_view_cup.dart';
import 'package:flutter/widgets.dart';

class const RestoreBootstrapView({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (getIt<PlatformStyle>().isCupertino) {
      return const RestoreBootstrapViewCup();
    }
    return const RestoreBootstrapViewAndr();
  }
}
