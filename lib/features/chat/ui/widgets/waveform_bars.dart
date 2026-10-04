import 'dart:math' as math;

import 'package:flutter/widgets.dart';

class const WaveformBars({
  super.key,
  required final List<double> values,
  required final Color playedColor,
  required final Color trackColor,

  final double progress = 1.0,
  final double barWidth = 3.0,
  final double gap = 2.0,

  final double minFraction = 0.15,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;

        final maxBars = maxWidth.isFinite
            ? math.max(1, maxWidth ~/ (barWidth + gap))
            : values.length;
        final List<double> visible;
        if (values.length <= maxBars) {
          visible = values;
        } else {
          visible = List.generate(maxBars, (i) {
            final src = (i * values.length / maxBars).floor().clamp(
              0,
              values.length - 1,
            );
            return values[src];
          });
        }
        return CustomPaint(
          painter: _WaveformPainter(
            values: visible,
            playedColor: playedColor,
            trackColor: trackColor,
            progress: progress.clamp(0.0, 1.0),
            barWidth: barWidth,
            gap: gap,
            minFraction: minFraction,
          ),
        );
      },
    );
  }
}

class const _WaveformPainter({
  required final List<double> values,
  required final Color playedColor,
  required final Color trackColor,
  required final double progress,
  required final double barWidth,
  required final double gap,
  required final double minFraction,
}) extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final playedPaint = Paint()
      ..color = playedColor
      ..strokeWidth = barWidth
      ..strokeCap = .round;
    final trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = barWidth
      ..strokeCap = .round;
    final playedCount = (values.length * progress).round();
    for (var i = 0; i < values.length; i++) {
      final fraction =
          minFraction + (1 - minFraction) * values[i].clamp(0.0, 1.0);
      final barHeight = size.height * fraction;
      final x = i * (barWidth + gap) + barWidth / 2;
      final y0 = (size.height - barHeight) / 2;
      canvas.drawLine(
        Offset(x, y0),
        Offset(x, y0 + barHeight),
        i < playedCount ? playedPaint : trackPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter old) =>
      old.values != values ||
      old.progress != progress ||
      old.playedColor != playedColor ||
      old.trackColor != trackColor;
}

class const RecordingDot({super.key, final double size = 12})
    extends StatefulWidget {
  @override
  State<RecordingDot> createState() => _RecordingDotState();
}

class _RecordingDotState()
    extends State<RecordingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween(
        begin: 1.0,
        end: 1.35,
      ).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut)),
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: const BoxDecoration(
          color: Color(0xFFFF3B30),
          shape: .circle,
        ),
      ),
    );
  }
}
