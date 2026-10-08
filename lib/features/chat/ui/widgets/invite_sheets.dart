import 'package:convetchat/app/adaptive/adaptive_text_field.dart';
import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/platform_style.dart';
import 'package:cupertino_ui/cupertino_ui.dart' as cup;
import 'package:flutter/services.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

Future<String?> openInviteOptionsSheet({required BuildContext context}) async {
  if (getIt<PlatformStyle>().isCupertino) {
    return cup.showCupertinoModalPopup<String>(
      context: context,
      builder: (_) => const _InviteOptionsSheet(),
    );
  }
  return showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (_) => const _InviteOptionsSheet(),
  );
}

String inviteLink(String roomId, String? canonicalAlias) {
  final target = canonicalAlias ?? roomId;
  return 'https://matrix.to/#/$target';
}

Future<void> copyInviteLink(
  BuildContext context,
  String roomId,
  String? canonicalAlias,
) async {
  await Clipboard.setData(
    ClipboardData(text: inviteLink(roomId, canonicalAlias)),
  );
}

class const _InviteOptionsSheet() extends StatelessWidget {
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
            if (isCupertino)
              cup.CupertinoButton.filled(
                onPressed: () => Navigator.of(context).pop('copy'),
                child: const Text('Скопировать ссылку'),
              )
            else
              M3EButton.outlined(
                size: .md,
                onPressed: () => Navigator.of(context).pop('copy'),
                child: const Text('Скопировать ссылку'),
              ),
            const SizedBox(height: 12),
            if (isCupertino)
              cup.CupertinoButton.filled(
                onPressed: () => Navigator.of(context).pop('pick'),
                child: const Text('Выбрать пользователей'),
              )
            else
              M3EButton.filled(
                size: .md,
                onPressed: () => Navigator.of(context).pop('pick'),
                child: const Text('Выбрать пользователей'),
              ),
          ],
        ),
      ),
    );
  }
}

Future<String?> openInviteReasonSheet(BuildContext context) {
  if (getIt<PlatformStyle>().isCupertino) {
    return cup.showCupertinoModalPopup<String>(
      context: context,
      builder: (_) => const _InviteReasonSheet(),
    );
  }
  return showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => const _InviteReasonSheet(),
  );
}

class const _InviteReasonSheet() extends StatefulWidget {
  @override
  State<_InviteReasonSheet> createState() => _InviteReasonSheetState();
}

class _InviteReasonSheetState() extends State<_InviteReasonSheet> {
  late final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottomInset),
        child: Column(
          mainAxisSize: .min,
          crossAxisAlignment: .stretch,
          children: [
            AdaptiveTextField(
              controller: _controller,
              label: 'Причина (необязательно)',
              onSubmitted: (_) => _send(),
            ),
            const SizedBox(height: 12),
            _SendButton(onSend: _send),
          ],
        ),
      ),
    );
  }

  void _send() {
    Navigator.of(context).pop(_controller.text.trim());
  }
}

class const _SendButton({required final VoidCallback onSend})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (getIt<PlatformStyle>().isCupertino) {
      return cup.CupertinoButton.filled(
        onPressed: onSend,
        child: const Text('Пригласить'),
      );
    }
    return FilledButton(onPressed: onSend, child: const Text('Пригласить'));
  }
}
