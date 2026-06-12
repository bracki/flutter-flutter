import 'package:flutter/material.dart';

/// Locked tie-dye anchor colors: pink, violet, green, amber.
const List<Color> acidPalette = [
  Color(0xFFff6ec4),
  Color(0xFF7873f5),
  Color(0xFF4ade80),
  Color(0xFFfacc15),
];

/// Wraps degrees into [0, 360).
double wrapHue(double degrees) {
  final m = degrees % 360;
  return m < 0 ? m + 360 : m;
}

/// Rotates a color's hue by [degrees].
Color shiftHue(Color c, double degrees) {
  final hsv = HSVColor.fromColor(c);
  return hsv.withHue(wrapHue(hsv.hue + degrees)).toColor();
}
