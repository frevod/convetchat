import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class const RecordMicButton({
  super.key,

  required final bool locked,
  required final VoidCallback onStart,
  required final VoidCallback onStop,
  required final VoidCallback onCancel,
  required final VoidCallback onLock,

  required final Widget Function(
    BuildContext context,
    Offset dragOffset,
    bool dragging,
  )
  buttonBuilder,
}) extends StatefulWidget {
  static const double cancelThreshold = -80;

  static const double lockThreshold = -64;

  static const Duration longPressTimeout = Duration(milliseconds: 200);

  @override
  State<RecordMicButton> createState() => _RecordMicButtonState();
}

class _RecordMicButtonState() extends State<RecordMicButton> {
  Offset _drag = Offset.zero;
  bool _active = false;
  bool _done = false;

  void _onLongPressStart(LongPressStartDetails _) {
    if (widget.locked) return;
    setState(() {
      _active = true;
      _done = false;
      _drag = Offset.zero;
    });
    HapticFeedback.mediumImpact();
    widget.onStart();
  }

  void _onMove(LongPressMoveUpdateDetails details) {
    if (!_active || _done || widget.locked) return;
    final dx = details.offsetFromOrigin.dx;
    final dy = details.offsetFromOrigin.dy;

    if (dx <= RecordMicButton.cancelThreshold) {
      setState(() {
        _drag = Offset.zero;
        _done = true;
        _active = false;
      });
      HapticFeedback.mediumImpact();
      widget.onCancel();
      return;
    }
    if (dy <= RecordMicButton.lockThreshold) {
      setState(() {
        _drag = Offset.zero;
        _done = true;
        _active = false;
      });
      HapticFeedback.heavyImpact();
      widget.onLock();
      return;
    }

    final Offset clamped;
    if (dx.abs() >= dy.abs()) {
      clamped = Offset(dx.clamp(-120.0, 0.0), 0);
    } else {
      clamped = Offset(0, dy.clamp(-120.0, 0.0));
    }
    setState(() => _drag = clamped);
  }

  void _onEnd(LongPressEndDetails _) {
    if (!_active) return;
    final wasDone = _done;
    setState(() {
      _drag = Offset.zero;
      _active = false;
    });
    if (!widget.locked && !wasDone) widget.onStop();
  }

  void _onCancel() {
    if (!_active && !_done) return;
    final wasDone = _done;
    final wasActive = _active;
    setState(() {
      _drag = Offset.zero;
      _active = false;
    });
    if (wasActive && !wasDone) {
      if (!widget.locked) widget.onCancel();
    }
  }

  @override
  void didUpdateWidget(RecordMicButton old) {
    super.didUpdateWidget(old);
    if (widget.locked && !old.locked && _drag != Offset.zero) {
      setState(() => _drag = Offset.zero);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      gestures: {
        LongPressGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
              () => LongPressGestureRecognizer(
                duration: RecordMicButton.longPressTimeout,
              ),
              (instance) {
                instance
                  ..onLongPressStart = _onLongPressStart
                  ..onLongPressMoveUpdate = _onMove
                  ..onLongPressEnd = _onEnd
                  ..onLongPressCancel = _onCancel;
              },
            ),
      },
      child: widget.buttonBuilder(context, _drag, _active),
    );
  }
}
