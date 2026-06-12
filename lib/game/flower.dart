import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'palette.dart';

/// A glowing flower. Blooms in over ~1s, then pulses; acts as a butterfly attractor.
class Flower extends PositionComponent {
  Flower({required Vector2 position, required this.hue})
      : super(position: position, size: Vector2.all(48), anchor: Anchor.center);

  double hue;
  double bloom = 0; // 0..1
  double _t = 0;

  @override
  void update(double dt) {
    bloom = (bloom + dt).clamp(0, 1).toDouble();
    _t += dt;
  }

  @override
  void render(Canvas canvas) {
    final pulse = 1 + 0.08 * math.sin(_t * 2);
    final r = (size.x / 2) * bloom * pulse;
    final base = shiftHue(acidPalette[3], hue); // amber-anchored
    final glow = Paint()
      ..color = base.withOpacity(0.9)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), r, glow);
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      r * 0.5,
      Paint()..color = Colors.white.withOpacity(0.85 * bloom),
    );
  }
}
