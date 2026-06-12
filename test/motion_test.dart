import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_acid/game/motion.dart';

void main() {
  test('seek returns velocity pointing toward the target', () {
    final v = seek(
      position: Vector2(0, 0),
      target: Vector2(100, 0),
      velocity: Vector2.zero(),
      maxSpeed: 50,
    );
    expect(v.x, greaterThan(0));
    expect(v.y.abs(), lessThan(0.001));
    expect(v.length, closeTo(50, 0.001));
  });

  test('scatterImpulse pushes away from center', () {
    final i = scatterImpulse(position: Vector2(10, 0), center: Vector2(0, 0), strength: 5);
    expect(i.x, greaterThan(0));
    expect(i.length, closeTo(5, 0.001));
  });

  test('clampToBounds keeps position inside the box', () {
    expect(clampToBounds(Vector2(-5, 500), Vector2(100, 200)), Vector2(0, 200));
  });

  test('wanderOffset stays small and bounded', () {
    for (var t = 0.0; t < 10; t += 0.3) {
      expect(wanderOffset(t, 1.0).length, lessThanOrEqualTo(1.5));
    }
  });
}
