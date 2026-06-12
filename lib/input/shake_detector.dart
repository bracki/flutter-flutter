import 'dart:async';
import 'dart:math' as math;
import 'package:sensors_plus/sensors_plus.dart';

/// Detects shakes from accelerometer magnitude with a cooldown debounce.
///
/// NOTE: the iOS Simulator has no accelerometer, so [start] emits nothing there.
/// Use the debug shake button (which calls the same onShake) to verify in the sim.
class ShakeDetector {
  ShakeDetector({
    required this.onShake,
    this.threshold = 15,
    this.cooldown = const Duration(milliseconds: 500),
  });

  final void Function() onShake;
  final double threshold;
  final Duration cooldown;
  DateTime? _last;
  StreamSubscription<UserAccelerometerEvent>? _sub;

  /// Pure, testable core. [now] is injected so tests control time.
  void handleSample(double x, double y, double z, DateTime now) {
    final magnitude = math.sqrt(x * x + y * y + z * z);
    if (magnitude < threshold) return;
    if (_last != null && now.difference(_last!) < cooldown) return;
    _last = now;
    onShake();
  }

  /// Subscribe to real accelerometer events (no-op data in the Simulator).
  void start() {
    _sub = userAccelerometerEventStream().listen((e) {
      handleSample(e.x, e.y, e.z, DateTime.now());
    });
  }

  void dispose() => _sub?.cancel();
}
