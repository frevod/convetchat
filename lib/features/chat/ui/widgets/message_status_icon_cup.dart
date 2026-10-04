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
      .read => _DoubleCheck(color: CupertinoColors.white),
      .failed => Icon(
        CupertinoIcons.exclamationmark,
        size: _size,
        color: CupertinoColors.systemRed.resolveFrom(context),
      ),
    };
  }
}

class const _DoubleCheck({required final Color color}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 14,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            child: Icon(CupertinoIcons.checkmark_alt, size: 10, color: color),
          ),
          Positioned(
            left: 6,
            child: Icon(CupertinoIcons.checkmark_alt, size: 10, color: color),
          ),
        ],
      ),
    );
  }
}
