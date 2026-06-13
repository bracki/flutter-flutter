import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_acid/game/tie_dye_background.dart';

void main() {
  test('background advances its animation phase on update', () {
    final bg = TieDyeBackground()..size = Vector2(400, 800);
    final p0 = bg.phase;
    bg.update(1.0);
    expect(bg.phase, greaterThan(p0));
  });
}
