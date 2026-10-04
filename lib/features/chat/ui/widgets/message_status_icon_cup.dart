import 'package:convetchat/features/chat/domain/entities/chat_message.dart';
import 'package:cupertino_ui/cupertino_ui.dart';

class const MessageStatusIconCup({
  super.key,
  required final MessageStatus status,
}) extends StatelessWidget {
  static const double _size = 14;

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      .sending => Icon(
        CupertinoIcons.clock,
        size: _size,
        color: CupertinoColors.systemGrey.resolveFrom(context),
      ),

      .sent => const SizedBox.shrink(),
      .read => const SizedBox.shrink(),
      .failed => Icon(
        CupertinoIcons.exclamationmark,
        size: _size,
        color: CupertinoColors.systemRed.resolveFrom(context),
      ),
    };
  }
}
