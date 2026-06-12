import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_acid/input/shake_detector.dart';

void main() {
  test('fires onShake when magnitude exceeds threshold', () {
    var fired = 0;
    final d = ShakeDetector(onShake: () => fired++, threshold: 15);
    final t0 = DateTime(2026, 1, 1, 0, 0, 0);
    d.handleSample(20, 0, 0, t0);
    expect(fired, 1);
  });

  test('does not fire below threshold', () {
    var fired = 0;
    final d = ShakeDetector(onShake: () => fired++, threshold: 15);
    d.handleSample(2, 2, 2, DateTime(2026));
    expect(fired, 0);
  });

  test('debounces within cooldown window', () {
    var fired = 0;
    final d = ShakeDetector(
      onShake: () => fired++,
      threshold: 15,
      cooldown: const Duration(milliseconds: 500),
    );
    final t0 = DateTime(2026, 1, 1, 0, 0, 0);
    d.handleSample(30, 0, 0, t0);
    d.handleSample(30, 0, 0, t0.add(const Duration(milliseconds: 100)));
    expect(fired, 1);
    d.handleSample(30, 0, 0, t0.add(const Duration(milliseconds: 700)));
    expect(fired, 2);
  });
}
