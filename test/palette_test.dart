import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_acid/game/palette.dart';

void main() {
  test('wrapHue keeps values in [0,360)', () {
    expect(wrapHue(0), 0);
    expect(wrapHue(360), 0);
    expect(wrapHue(400), 40);
    expect(wrapHue(-30), 330);
  });

  test('shiftHue by 360 returns an equivalent hue', () {
    const c = Color(0xFFff6ec4);
    final shifted = shiftHue(c, 360);
    expect(HSVColor.fromColor(shifted).hue, closeTo(HSVColor.fromColor(c).hue, 0.5));
  });

  test('acidPalette has the four locked anchor colors', () {
    expect(acidPalette.length, 4);
    expect(acidPalette.first, const Color(0xFFff6ec4));
  });
}
