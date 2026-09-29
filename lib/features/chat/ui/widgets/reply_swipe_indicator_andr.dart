import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

class const ReplySwipeIndicatorAndr({super.key, required final double progress})
    extends StatelessWidget {
  static const _size = 40.0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: _size,
      height: _size,
      child: Stack(
        alignment: .center,
        children: [
          M3EProgressIndicator.circularWavy(
            value: progress,
            size: _size,
            color: scheme.primary,
          ),
          Icon(Icons.reply_rounded, size: 20, color: scheme.primary),
        ],
      ),
    );
  }
}
