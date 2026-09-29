import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/platform_style.dart';
import 'package:convetchat/core/utils/message_format.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';

class const VerificationAvatar({
  super.key,
  required final String name,
  final double radius = 24,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final initial = avatarInitial(name);
    final Color background;
    final Color foreground;
    if (getIt<PlatformStyle>().isCupertino) {
      background = CupertinoColors.activeBlue.resolveFrom(context);
      foreground = CupertinoColors.white;
    } else {
      final scheme = Theme.of(context).colorScheme;
      background = scheme.primary;
      foreground = scheme.onPrimary;
    }
    if (getIt<PlatformStyle>().isCupertino) {
      return Container(
        width: radius * 2,
        height: radius * 2,
        alignment: .center,
        decoration: BoxDecoration(color: background, shape: .circle),
        child: Text(
          initial,
          style: TextStyle(fontSize: radius, color: foreground),
        ),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: background,
      foregroundColor: foreground,
      child: Text(initial, style: TextStyle(fontSize: radius)),
    );
  }
}
