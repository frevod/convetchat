import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/platform_style.dart';
import 'package:convetchat/features/encryption/ui/widgets/restore_key_input_andr.dart';
import 'package:convetchat/features/encryption/ui/widgets/restore_key_input_cup.dart';
import 'package:flutter/widgets.dart';

class const RestoreKeyInput({
  super.key,
  required final TextEditingController controller,
  required final bool isLoading,
  required final bool obscureText,
  required final bool keyEntered,
  required final Object? unlockError,
  required final VoidCallback onToggleObscure,
  required final VoidCallback onUnlock,
  required final VoidCallback onOpenKeyFile,
  required final ValueChanged<String> onSubmitted,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (getIt<PlatformStyle>().isCupertino) {
      return RestoreKeyInputCup(
        controller: controller,
        isLoading: isLoading,
        obscureText: obscureText,
        keyEntered: keyEntered,
        unlockError: unlockError,
        onToggleObscure: onToggleObscure,
        onUnlock: onUnlock,
        onOpenKeyFile: onOpenKeyFile,
      );
    }
    return RestoreKeyInputAndr(
      controller: controller,
      isLoading: isLoading,
      obscureText: obscureText,
      keyEntered: keyEntered,
      unlockError: unlockError,
      onToggleObscure: onToggleObscure,
      onUnlock: onUnlock,
      onOpenKeyFile: onOpenKeyFile,
      onSubmitted: onSubmitted,
    );
  }
}
