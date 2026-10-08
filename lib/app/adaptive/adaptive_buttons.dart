import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/platform_style.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

abstract class AdaptiveButton() {
  static Widget filled({
    required Widget child,
    required VoidCallback onPressed,
    bool enabled = true,
    bool isDestructive = false,
  }) {
    if (getIt<PlatformStyle>().isCupertino) {
      return Builder(
        builder: (context) {
          final btnColor = isDestructive
              ? CupertinoColors.destructiveRed.resolveFrom(context)
              : CupertinoColors.systemBlue.resolveFrom(context);
          return CupertinoButton.filled(
            onPressed: enabled ? onPressed : null,
            color: btnColor,
            sizeStyle: .medium,
            child: child,
          );
        },
      );
    } else {
      return M3EButton.filled(
        size: .md,
        onPressed: onPressed,
        enabled: enabled,
        decoration: isDestructive
            ? M3EButtonDecoration(
                backgroundColor: WidgetStatePropertyAll(Colors.redAccent),
              )
            : null,
        child: child,
      );
    }
  }

  static Widget outlined({
    required Widget child,
    required VoidCallback onPressed,
    bool enabled = true,
  }) {
    if (getIt<PlatformStyle>().isCupertino) {
      return CupertinoButton.tinted(
        onPressed: enabled ? onPressed : null,
        sizeStyle: .medium,
        child: child,
      );
    } else {
      return M3EButton.outlined(
        size: .md,
        onPressed: onPressed,
        enabled: enabled,
        child: child,
      );
    }
  }
}
