import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class const SwipeToReply({
  super.key,

  required final Widget child,

  required final VoidCallback onReply,

  required final Widget Function(BuildContext context, double progress)
  actionBuilder,
}) extends StatefulWidget {
  static const double replyThreshold = 64;

  static const double maxDrag = 128;

  @override
  State<SwipeToReply> createState() => _SwipeToReplyState();
}

class _SwipeToReplyState()
    extends State<SwipeToReply>
    with SingleTickerProviderStateMixin {
  double _offset = 0;
  bool _vibrated = false;
  Animation<double>? _snapAnim;
  late final AnimationController _snap = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
  );

  @override
  void dispose() {
    _snap.dispose();
    super.dispose();
  }

  void _onUpdate(DragUpdateDetails details) {
    _snap.stop();
    setState(() {
      _offset = (_offset + details.delta.dx).clamp(-SwipeToReply.maxDrag, 0);
    });

    if (_offset <= -SwipeToReply.maxDrag && !_vibrated) {
      _vibrated = true;
      HapticFeedback.lightImpact();
    } else if (_offset > -SwipeToReply.maxDrag + 24) {
      _vibrated = false;
    }
  }

  void _onEnd(DragEndDetails details) {
    if (_offset <= -SwipeToReply.replyThreshold) {
      widget.onReply();
    }
    _snapAnim =
        Tween<double>(begin: _offset, end: 0).animate(
          CurvedAnimation(parent: _snap, curve: Curves.easeOut),
        )..addListener(() {
          setState(() => _offset = _snapAnim!.value);
        });
    _snap.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final progress = (-_offset / SwipeToReply.maxDrag).clamp(0, 1);
    return GestureDetector(
      behavior: .opaque,
      onHorizontalDragUpdate: _onUpdate,
      onHorizontalDragEnd: _onEnd,
      child: Stack(
        children: [
          if (_offset < 0)
            Positioned.fill(
              child: Align(
                alignment: .centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: widget.actionBuilder(context, progress.toDouble()),
                ),
              ),
            ),
          Transform.translate(offset: Offset(_offset, 0), child: widget.child),
        ],
      ),
    );
  }
}
