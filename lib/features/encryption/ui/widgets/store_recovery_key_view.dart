import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/platform_style.dart';
import 'package:convetchat/features/encryption/ui/widgets/store_recovery_key_view_andr.dart';
import 'package:convetchat/features/encryption/ui/widgets/store_recovery_key_view_cup.dart';
import 'package:flutter/widgets.dart';

class const StoreRecoveryKeyView({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (getIt<PlatformStyle>().isCupertino) {
      return const StoreRecoveryKeyViewCup();
    }
    return const StoreRecoveryKeyViewAndr();
  }
}
