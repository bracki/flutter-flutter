import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'flutter_game.dart';
import 'flower.dart';
import 'motion.dart';
import 'palette.dart';

class Butterfly extends PositionComponent
    with TapCallbacks, HasGameReference<FlutterGame> {
  Butterfly({required Vector2 position, required this.hue, this.seed = 0})
      : super(position: position, size: Vector2(40, 32), anchor: Anchor.center);

  double hue;
  final double seed;
  Vector2 velocity = Vector2.zero();
  Vector2 bounds = Vector2(400, 800);
  Flower? target;
  bool caught = false;
  double maxSpeed = 90;
  double _flap = 0;

  void applyImpulse(Vector2 impulse) => velocity += impulse;

  @override
  void update(double dt) {
    if (caught) return;
    _flap += dt * 18;
    if (target != null) {
      final steer = seek(
        position: position,
        target: target!.position,
        velocity: velocity,
        maxSpeed: maxSpeed,
      );
      velocity = velocity * 0.92 + steer * 0.08;
    }
    velocity += wanderOffset(_flap * 0.1, seed) * 6 * dt;
    position.add(velocity * dt);
    position.setFrom(clampToBounds(position, bounds));
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (!caught && isMounted) {
      game.catchButterfly(this);
    }
  }

  @override
  void render(Canvas canvas) {
    final wingScale = 0.25 + 0.75 * (0.5 + 0.5 * math.sin(_flap));
    final color = shiftHue(acidPalette[(seed.toInt()) % acidPalette.length], hue);
    final glow = Paint()
      ..color = color
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    final wing = Paint()..color = color;
    final core = Paint()..color = Colors.white.withValues(alpha: 0.9);
    final cx = size.x / 2, cy = size.y / 2;
    for (final sign in [-1.0, 1.0]) {
      final center = Offset(cx + sign * 10 * wingScale, cy);
      final rect = Rect.fromCenter(center: center, width: 18 * wingScale, height: 28);
      canvas.drawOval(rect.inflate(4), glow); // bright halo
      canvas.drawOval(rect, wing); // saturated wing
      canvas.drawOval(
        Rect.fromCenter(center: center, width: 8 * wingScale, height: 12),
        core,
      ); // white core so it reads against the tie-dye
    }
    // dark body for definition
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy), width: 4, height: 24),
        const Radius.circular(2),
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.65),
    );
  }
}
