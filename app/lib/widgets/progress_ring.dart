import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A determinate ring that sweeps clockwise from 12 o'clock.
///
/// CircularProgressIndicator could show the same value, but not at this size
/// with a rounded cap and a child inside, so the arc is painted directly.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.value,
    required this.color,
    required this.trackColor,
    this.thickness = 16,
    this.child,
  });

  /// Progress from 0 to 1.
  final double value;
  final Color color;
  final Color trackColor;
  final double thickness;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      builder: (context, animated, _) {
        return CustomPaint(
          painter: _RingPainter(
            value: animated,
            color: color,
            trackColor: trackColor,
            thickness: thickness,
          ),
          child: Center(child: child),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.value,
    required this.color,
    required this.trackColor,
    required this.thickness,
  });

  final double value;
  final Color color;
  final Color trackColor;
  final double thickness;

  @override
  void paint(Canvas canvas, Size size) {
    final side = math.min(size.width, size.height);
    if (side <= 0) return;

    final centre = Offset(size.width / 2, size.height / 2);
    final radius = (side - thickness) / 2;

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round
      ..color = trackColor;
    canvas.drawCircle(centre, radius, track);

    if (value <= 0) return;

    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round
      ..color = color;

    canvas.drawArc(
      Rect.fromCircle(center: centre, radius: radius),
      -math.pi / 2,
      2 * math.pi * value,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value ||
      old.color != color ||
      old.trackColor != trackColor ||
      old.thickness != thickness;
}
