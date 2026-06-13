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
  Butterfly({required Vector2 position, required this.hue, double seed = 0})
      : _seed = seed,
        super(position: position, size: Vector2(40, 32), anchor: Anchor.center);

  double hue;
  final double _seed;
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
    velocity += wanderOffset(_flap * 0.1, _seed) * 6 * dt;
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
    final color = shiftHue(acidPalette[(_seed.toInt()) % acidPalette.length], hue);
    final glow = Paint()
      ..color = color
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    final cx = size.x / 2, cy = size.y / 2;
    for (final sign in [-1.0, 1.0]) {
      final rect = Rect.fromCenter(
        center: Offset(cx + sign * 9 * wingScale, cy),
        width: 16 * wingScale,
        height: 26,
      );
      canvas.drawOval(rect, glow);
    }
  }
}
