import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/platform_style.dart';
import 'package:convetchat/features/chats/domain/entities/join_rule.dart';
import 'package:cupertino_ui/cupertino_ui.dart' as cup;
import 'package:material_ui/material_ui.dart';

String joinRuleLabel(String joinRule) {
  if (joinRule == JoinRule.public) return 'Открытая';
  if (joinRule == JoinRule.knock || joinRule == JoinRule.knockRestricted) {
    return 'По заявкам';
  }
  return 'По приглашениям';
}

String joinRuleDescription(String joinRule) {
  if (joinRule == JoinRule.public) return 'Войти может кто угодно';
  if (joinRule == JoinRule.knock || joinRule == JoinRule.knockRestricted) {
    return 'Вход после одобрения заявки';
  }
  return 'Вход только по приглашению';
}

const joinRuleOptions = [JoinRule.public, JoinRule.knock, JoinRule.invite];

Future<String?> openJoinRuleSheet({
  required BuildContext context,
  required String current,
}) {
  final sheet = _JoinRuleSheet(current: current);
  if (getIt<PlatformStyle>().isCupertino) {
    return cup.showCupertinoModalPopup<String>(
      context: context,
      builder: (_) => sheet,
    );
  }
  return showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (_) => sheet,
  );
}

class const _JoinRuleSheet({required final String current})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isCupertino = getIt<PlatformStyle>().isCupertino;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: .min,
          crossAxisAlignment: .stretch,
          children: [
            for (final option in joinRuleOptions)
              _OptionRow(
                label: joinRuleLabel(option),
                description: joinRuleDescription(option),
                selected: option == current,
                isCupertino: isCupertino,
                onTap: () => Navigator.of(context).pop(option),
              ),
          ],
        ),
      ),
    );
  }
}

class const _OptionRow({
  required final String label,
  required final String description,
  required final bool selected,
  required final bool isCupertino,
  required final VoidCallback onTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: .opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: .start,
                mainAxisSize: .min,
                children: [
                  Text(label, style: const TextStyle(fontSize: 16)),
                  Text(description, style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
            if (selected)
              isCupertino
                  ? const Icon(cup.CupertinoIcons.checkmark)
                  : const Icon(Icons.check_rounded),
          ],
        ),
      ),
    );
  }
}
