import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/utils/safe_text.dart';
import 'package:flutter/material.dart' as material
    show ScaffoldMessenger, SnackBar, Text;
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart'
    hide ScaffoldMessenger, ScaffoldMessengerState;
import 'package:talker_flutter/talker_flutter.dart';

class const TalkerLogPage({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return material.ScaffoldMessenger(
      child: TalkerScreen(
        talker: getIt<Talker>(),
        itemsBuilder: _safeItemBuilder,
      ),
    );
  }
}

Widget _safeItemBuilder(BuildContext context, TalkerData data) {
  const theme = TalkerScreenTheme();
  return _SafeTalkerCard(data: data, theme: theme);
}

void _copySafe(BuildContext context, TalkerData data) {
  final talker = getIt<Talker>();
  final raw = data.generateTextMessage(
    timeFormat: talker.settings.timeFormat,
  );
  Clipboard.setData(ClipboardData(text: sanitizeForText(raw)));
  material.ScaffoldMessenger.maybeOf(context)?.showSnackBar(
    const material.SnackBar(content: material.Text('Лог скопирован')),
  );
}

class const _SafeTalkerCard({
  required final TalkerData data,
  required final TalkerScreenTheme theme,
}) extends StatefulWidget {

  @override
  State<_SafeTalkerCard> createState() => _SafeTalkerCardState();
}

class _SafeTalkerCardState() extends State<_SafeTalkerCard> {
  var _expanded = true;

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final color = data.getFlutterColor(widget.theme);
    final title = sanitizeForText('${data.title} | ${data.displayTime()}');
    final message = data.displayMessage.isEmpty
        ? null
        : sanitizeForText(data.displayMessage);
    final hasError = data.exception != null || data.error != null;
    final type = hasError
        ? sanitizeForText(
            'Type: ${data.exception?.runtimeType ?? data.error.runtimeType}',
          )
        : null;
    var errorMessage =
        data.exception?.toString() ?? data.error?.toString();
    if ((errorMessage?.isNotEmpty ?? false) &&
        errorMessage!.contains('Source stack:')) {
      errorMessage =
          'Data: ${errorMessage.split('Source stack:').first.replaceAll('\n', '')}';
    }
    final errorText = (errorMessage == null || errorMessage.isEmpty)
        ? null
        : sanitizeForText(errorMessage);
    final stack = data.stackTrace == null
        ? null
        : sanitizeForText('StackTrace:\n${data.stackTrace}');

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => setState(() => _expanded = !_expanded),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: widget.theme.cardColor,
            borderRadius: .circular(10),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Column(
            crossAxisAlignment: .start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: .start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: color,
                            fontWeight: .w700,
                            fontSize: 14,
                          ),
                        ),
                        if (message != null)
                          Text(
                            message,
                            maxLines: _expanded ? null : 2,
                            style: TextStyle(color: color, fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 20,
                    width: 20,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      iconSize: 20,
                      icon: Icon(Icons.copy, color: color),
                      onPressed: () => _copySafe(context, data),
                    ),
                  ),
                ],
              ),
              if (_expanded && (type != null || errorText != null))
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF212121),
                    borderRadius: .circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: .start,
                    children: [
                      if (type != null)
                        Text(
                          type,
                          style: TextStyle(color: color, fontSize: 12),
                        ),
                      if (errorText != null)
                        Text(
                          errorText,
                          style: TextStyle(color: color, fontSize: 12),
                        ),
                    ],
                  ),
                ),
              if (_expanded && stack != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF212121),
                    borderRadius: .circular(10),
                  ),
                  child: Text(
                    stack,
                    style: TextStyle(color: color, fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
