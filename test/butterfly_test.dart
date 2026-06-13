import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_acid/game/butterfly.dart';

void main() {
  test('butterfly integrates velocity into position', () {
    final b = Butterfly(position: Vector2(50, 50), hue: 0)
      ..bounds = Vector2(400, 800)
      ..velocity = Vector2(10, 0);
    b.update(1.0);
    expect(b.position.x, greaterThan(50));
  });

  test('applyImpulse increases speed', () {
    final b = Butterfly(position: Vector2(50, 50), hue: 0)..velocity = Vector2(1, 0);
    final before = b.velocity.length;
    b.applyImpulse(Vector2(20, 0));
    expect(b.velocity.length, greaterThan(before));
  });

  test('butterfly stays within bounds', () {
    final b = Butterfly(position: Vector2(10, 10), hue: 0)
      ..bounds = Vector2(200, 200)
      ..velocity = Vector2(-9999, -9999);
    b.update(1.0);
    expect(b.position.x, inInclusiveRange(0, 200));
    expect(b.position.y, inInclusiveRange(0, 200));
  });
}
