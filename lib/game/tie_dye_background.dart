import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'palette.dart';

/// Full-viewport swirling rainbow gradient.
class TieDyeBackground extends PositionComponent {
  TieDyeBackground() : super(priority: -1);

  double phase = 0;
  double hueOffset = 0;

  @override
  void update(double dt) => phase += dt * 0.15;

  @override
  void render(Canvas canvas) {
    final t = phase % 1.0;
    final a = Alignment(math.cos(t * 2 * math.pi), math.sin(t * 2 * math.pi));
    final colors = [for (final c in acidPalette) shiftHue(c, hueOffset)]
      ..add(shiftHue(acidPalette.first, hueOffset));
    final rect = Offset.zero & Size(size.x, size.y);
    final paint = Paint()
      ..shader = LinearGradient(begin: a, end: -a, colors: colors).createShader(rect);
    canvas.drawRect(rect, paint);
  }
}
