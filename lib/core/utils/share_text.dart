import 'package:convetchat/app/adaptive/adaptive_snackbar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:share_plus/share_plus.dart';

Future<void> shareText(String text, BuildContext context) async {
  if (defaultTargetPlatform == .android || defaultTargetPlatform == .iOS) {
    final box = context.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(
      ShareParams(
        text: text,
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(.zero) & box.size,
      ),
    );
    return;
  }
  await Clipboard.setData(ClipboardData(text: text));
  if (!context.mounted) return;
  AdaptiveSnackbar.show(
    context: context,
    message: 'Скопировано в буфер обмена',
    type: .success,
  );
}
