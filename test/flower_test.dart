import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_acid/game/flower.dart';

void main() {
  test('flower blooms from 0 toward 1 over time', () {
    final f = Flower(position: Vector2(10, 10), hue: 0);
    expect(f.bloom, 0);
    f.update(0.5);
    expect(f.bloom, greaterThan(0));
    for (var i = 0; i < 100; i++) {
      f.update(0.1);
    }
    expect(f.bloom, 1.0);
  });
}
