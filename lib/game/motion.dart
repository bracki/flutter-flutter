import 'dart:math' as math;
import 'package:flame/components.dart';

/// Desired velocity steering [position] toward [target], capped at [maxSpeed].
Vector2 seek({
  required Vector2 position,
  required Vector2 target,
  required Vector2 velocity,
  required double maxSpeed,
}) {
  final desired = target - position;
  if (desired.length == 0) return Vector2.zero();
  desired.scaleTo(maxSpeed);
  return desired;
}

/// Outward impulse pushing [position] away from [center], magnitude [strength].
Vector2 scatterImpulse({
  required Vector2 position,
  required Vector2 center,
  required double strength,
}) {
  final dir = position - center;
  if (dir.length == 0) return Vector2(strength, 0);
  dir.scaleTo(strength);
  return dir;
}

/// Clamps [position] into the [0,bounds] box.
Vector2 clampToBounds(Vector2 position, Vector2 bounds) {
  return Vector2(
    position.x.clamp(0, bounds.x).toDouble(),
    position.y.clamp(0, bounds.y).toDouble(),
  );
}

/// Small smooth wander offset for organic flight; bounded by ~1.5.
Vector2 wanderOffset(double t, double seed) {
  return Vector2(math.sin(t * 1.7 + seed), math.cos(t * 1.3 + seed * 2));
}
