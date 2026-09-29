import 'package:convetchat/app/adaptive/adaptive_loading_indicator.dart';
import 'package:convetchat/features/chat/domain/entities/chat_message.dart';
import 'package:material_ui/material_ui.dart';

class const MessageStatusIconAndr({
  super.key,
  required final MessageStatus status,
}) extends StatelessWidget {
  static const double _size = 14;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return switch (status) {
      .sending => SizedBox(
        width: 12,
        height: 12,
        child: AdaptiveLoadingIndicator(color: scheme.onPrimary),
      ),

      .sent => const SizedBox.shrink(),
      .read => Icon(Icons.done_all, size: _size, color: scheme.onPrimary),
      .failed => Icon(Icons.error_rounded, size: _size, color: scheme.error),
    };
  }
}
