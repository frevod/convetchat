import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/platform_style.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_3_expressive/components/buttons/m3e_buttons.dart';
import 'package:material_ui/material_ui.dart';

class const DialogAction({
  super.key,
  required final VoidCallback onPressed,
  required final Widget child,
  final bool destructive = false,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (getIt<PlatformStyle>().isCupertino) {
      return CupertinoDialogAction(
        isDestructiveAction: destructive,
        onPressed: onPressed,
        child: child,
      );
    }
    if (destructive) {
      return M3EButton.outlined(
        onPressed: onPressed,
        child: DefaultTextStyle(
          style: TextStyle(color: Theme.of(context).colorScheme.error),
          child: child,
        ),
      );
    }
    return M3EButton.filled(onPressed: onPressed, child: child);
  }
}
