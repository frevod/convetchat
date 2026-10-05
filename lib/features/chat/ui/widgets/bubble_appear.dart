import 'package:flutter/widgets.dart';

class const BubbleAppear({
  super.key,
  required final bool isOwn,
  required final bool fresh,
  required final Widget child,
}) extends StatefulWidget {
  @override
  State<BubbleAppear> createState() => _BubbleAppearState();
}

class _BubbleAppearState()
    extends State<BubbleAppear>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    if (!widget.fresh) return;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    final curve = CurvedAnimation(
      parent: _controller!,
      curve: Curves.easeOutCubic,
    );
    _opacity = Tween<double>(begin: 0, end: 1).animate(curve);
    _offset = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(curve);
    _scale = Tween<double>(begin: 0.9, end: 1).animate(curve);
    _controller!.forward();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) return widget.child;
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _offset,
        child: ScaleTransition(
          scale: _scale,
          alignment: widget.isOwn
              ? Alignment.bottomRight
              : Alignment.bottomLeft,
          child: widget.child,
        ),
      ),
    );
  }
}
