import 'dart:math';

import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

class PinShapeIndicator extends StatefulWidget {
  const PinShapeIndicator({required this.filled, this.length = 4, super.key});

  final int filled;
  final int length;

  @override
  State<PinShapeIndicator> createState() => _PinShapeIndicatorState();
}

class _PinShapeIndicatorState extends State<PinShapeIndicator> {
  static const _pool = [
    M3EShapeKind.cookie4Sided,
    M3EShapeKind.cookie6Sided,
    M3EShapeKind.cookie7Sided,
    M3EShapeKind.cookie9Sided,
    M3EShapeKind.cookie12Sided,
    M3EShapeKind.clover4Leaf,
    M3EShapeKind.clover8Leaf,
    M3EShapeKind.burst,
    M3EShapeKind.softBurst,
    M3EShapeKind.boom,
    M3EShapeKind.softBoom,
    M3EShapeKind.flower,
    M3EShapeKind.puffy,
    M3EShapeKind.puffyDiamond,
    M3EShapeKind.gem,
    M3EShapeKind.sunny,
    M3EShapeKind.verySunny,
    M3EShapeKind.diamond,
    M3EShapeKind.triangle,
    M3EShapeKind.fan,
    M3EShapeKind.clamShell,
    M3EShapeKind.pentagon,
    M3EShapeKind.ghostish,
    M3EShapeKind.bun,
    M3EShapeKind.heart,
    M3EShapeKind.pixelCircle,
    M3EShapeKind.arrow,
  ];

  final _random = Random();
  final _kinds = <M3EShapeKind>[];
  final _nonces = <int>[];
  int _seenFilled = 0;

  M3EShapeKind _draw() => _pool[_random.nextInt(_pool.length)];

  void _sync(int filled) {
    while (_kinds.length < widget.length) {
      _kinds.add(_draw());
      _nonces.add(0);
    }
    final target = filled.clamp(0, widget.length);
    for (var i = _seenFilled; i < target; i++) {
      _kinds[i] = _draw();
      _nonces[i]++;
    }
    _seenFilled = target;
  }

  @override
  void initState() {
    super.initState();
    _sync(widget.filled);
  }

  @override
  void didUpdateWidget(PinShapeIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync(widget.filled);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 14,
      children: [
        for (var i = 0; i < widget.length; i++)
          SizedBox(
            width: 28,
            height: 28,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 380),
              reverseDuration: const Duration(milliseconds: 180),
              switchInCurve: Curves.easeOutBack,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) => RotationTransition(
                turns: Tween<double>(begin: -0.6, end: 0).animate(animation),
                child: ScaleTransition(scale: animation, child: child),
              ),
              child: i < _seenFilled
                  ? M3EShapeContainer(
                      key: ValueKey('filled_${_nonces[i]}'),
                      kind: _kinds[i],
                      width: 24,
                      height: 24,
                      color: scheme.primary,
                    )
                  : M3EShapeContainer.circle(
                      key: const ValueKey('empty'),
                      width: 12,
                      height: 12,
                      color: scheme.surfaceContainerHighest,
                    ),
            ),
          ),
      ],
    );
  }
}
