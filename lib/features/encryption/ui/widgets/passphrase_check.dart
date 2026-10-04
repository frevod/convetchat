import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/platform_style.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';

class const PassphraseCheck({
  super.key,
  required final bool checked,
  required final String label,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (getIt<PlatformStyle>().isCupertino) {
      return Row(
        spacing: 8.0,
        children: [
          Icon(
            checked ? CupertinoIcons.check_mark_circled : CupertinoIcons.circle,
            color: checked
                ? CupertinoColors.systemGreen.resolveFrom(context)
                : CupertinoColors.systemRed.resolveFrom(context),
            size: 20,
          ),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      );
    }
    final theme = Theme.of(context);
    return Row(
      spacing: 8.0,
      children: [
        Icon(
          checked ? Icons.check_circle_outline_rounded : Icons.circle_outlined,
          color: checked
              ? (theme.brightness == .light
                    ? Colors.green.shade800
                    : Colors.green.shade300)
              : theme.colorScheme.error,
          size: 20,
        ),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
