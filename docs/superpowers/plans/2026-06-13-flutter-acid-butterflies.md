# Flutter — Acid Flutterbies Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build an ambient iOS app where glowing neon butterflies drift across a tie-dye rainbow background and onto glowing flowers; tap to catch them, shake for a scatter + bloom + color-shift burst.

**Architecture:** A Flame `FlameGame` drives a 60fps loop. Each butterfly/flower is a `PositionComponent`. Motion and palette math live in pure top-level functions (`motion.dart`, `palette.dart`) so they unit-test without the engine. A `ShakeDetector` wraps `sensors_plus`; a debug button calls the same `onShake` path so shake is verifiable in the Simulator. A Flutter overlay renders the caught counter.

**Tech Stack:** Flutter (Dart), Flame game engine, sensors_plus, flutter_test + flame_test.

---

## File Structure

| File | Responsibility |
|------|----------------|
| `lib/main.dart` | App entry; `GameWidget` + HUD overlay + debug shake button |
| `lib/game/palette.dart` | Pure hue math: `wrapHue`, `shiftHue`, base palette |
| `lib/game/motion.dart` | Pure steering math: `seek`, `wanderOffset`, `scatterImpulse`, `clampToBounds` |
| `lib/game/flower.dart` | `Flower` PositionComponent: hue, bloom-in, glow render, attractor |
| `lib/game/butterfly.dart` | `Butterfly` PositionComponent + TapCallbacks: steering, flap, glow, catch |
| `lib/game/tie_dye_background.dart` | Full-viewport animated swirling gradient component |
| `lib/game/flutter_game.dart` | The `FlameGame`: state, counter, scatter/bloom/shiftPalette/onShake/catch |
| `lib/input/shake_detector.dart` | Accelerometer wrapper → `onShake`; pure `handleSample` |
| `lib/ui/hud.dart` | Overlay widget: caught counter + debug shake button |

## Parallelization map (waves)

Tasks within a wave are independent and can be dispatched concurrently. Later waves depend on earlier ones.

- **Wave 0 (serial):** Task 1 (install + scaffold), then Task 2 (deps). Everything else depends on these.
- **Wave 1 (parallel):** Task 3 `palette`, Task 4 `motion`, Task 8 `shake_detector`, Task 9 `hud`. Four independent leaf modules — no shared files.
- **Wave 2 (parallel):** Task 5 `flower` (needs palette), Task 6 `butterfly` (needs motion + palette).
- **Wave 3 (serial):** Task 7 `flutter_game` (needs flower + butterfly + palette), then Task 10 `tie_dye_background`, then Task 11 `main.dart` wiring + Simulator acceptance.

---

## Task 1: Install Flutter & scaffold the iOS project

**Files:**
- Create: whole `flutter create` scaffold in repo root.

- [ ] **Step 1: Install the Flutter SDK**

Run:
```bash
brew install --cask flutter
flutter --version
```
Expected: prints a Flutter + Dart version. If `brew` cask fails, fall back to:
`git clone -b stable https://github.com/flutter/flutter.git ~/flutter && export PATH="$HOME/flutter/bin:$PATH"`.

- [ ] **Step 2: Check the toolchain**

Run: `flutter doctor`
Expected: Flutter ✓ and Xcode ✓ (CocoaPods present). Android entries may show ✗ — fine, we target iOS.

- [ ] **Step 3: Scaffold the app into the repo root**

The repo root already has `.git`, `docs/`, `.gitignore`. Scaffold into a temp dir and move files in to avoid clobbering:
```bash
flutter create --org io.superluminar --project-name flutter_acid --platforms=ios /tmp/flutter_acid
rsync -a --exclude='.git' /tmp/flutter_acid/ .
```
Expected: `lib/main.dart`, `pubspec.yaml`, `ios/` now exist in repo root.

- [ ] **Step 4: Append Flutter ignores to `.gitignore`**

Add Flutter's standard ignores (`.dart_tool/`, `build/`, `.flutter-plugins*`, `ios/Pods/`, etc.) — copy the block `flutter create` generated in `/tmp/flutter_acid/.gitignore` and merge it, keeping the existing `.superpowers/` line.

- [ ] **Step 5: Smoke-test on the iOS Simulator**

Run:
```bash
xcrun simctl boot "iPhone 15" || true
open -a Simulator
flutter run -d "iPhone 15" --no-hot
```
Expected: the default counter app launches in the Simulator. Press `q` to quit.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "scaffold flutter ios app"
```

---

## Task 2: Add dependencies

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Add runtime + dev deps**

Run:
```bash
flutter pub add flame sensors_plus
flutter pub add --dev flame_test
```
Expected: `pubspec.yaml` lists `flame`, `sensors_plus`, and dev `flame_test`; `flutter pub get` succeeds.

- [ ] **Step 2: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "add flame and sensors_plus deps"
```

---

## Task 3: Palette (pure hue math) — TDD

**Files:**
- Create: `lib/game/palette.dart`
- Test: `test/palette_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/palette_test.dart
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/palette_test.dart`
Expected: FAIL — `palette.dart` / symbols not defined.

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/game/palette.dart
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
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/palette_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/game/palette.dart test/palette_test.dart
git commit -m "add palette hue math"
```

---

## Task 4: Motion (pure steering math) — TDD

**Files:**
- Create: `lib/game/motion.dart`
- Test: `test/motion_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/motion_test.dart
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/motion_test.dart`
Expected: FAIL — symbols not defined.

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/game/motion.dart
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
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/motion_test.dart`
Expected: PASS (4 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/game/motion.dart test/motion_test.dart
git commit -m "add motion steering math"
```

---

## Task 5: Flower component — TDD (depends on palette)

**Files:**
- Create: `lib/game/flower.dart`
- Test: `test/flower_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/flower_test.dart
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/flower_test.dart`
Expected: FAIL — `Flower` not defined.

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/game/flower.dart
import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'palette.dart';

/// A glowing flower. Blooms in over ~1s, then pulses; acts as a butterfly attractor.
class Flower extends PositionComponent {
  Flower({required Vector2 position, required this.hue})
      : super(position: position, size: Vector2.all(48), anchor: Anchor.center);

  double hue;
  double bloom = 0; // 0..1
  double _t = 0;

  @override
  void update(double dt) {
    bloom = (bloom + dt).clamp(0, 1).toDouble();
    _t += dt;
  }

  @override
  void render(Canvas canvas) {
    final pulse = 1 + 0.08 * math.sin(_t * 2);
    final r = (size.x / 2) * bloom * pulse;
    final base = shiftHue(acidPalette[3], hue); // amber-anchored
    final glow = Paint()
      ..color = base.withOpacity(0.9)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), r, glow);
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      r * 0.5,
      Paint()..color = Colors.white.withOpacity(0.85 * bloom),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/flower_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/game/flower.dart test/flower_test.dart
git commit -m "add flower component"
```

---

## Task 6: Butterfly component — TDD (depends on motion + palette)

**Files:**
- Create: `lib/game/butterfly.dart`
- Test: `test/butterfly_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/butterfly_test.dart
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/butterfly_test.dart`
Expected: FAIL — `Butterfly` not defined.

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/game/butterfly.dart
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
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/butterfly_test.dart`
Expected: PASS (3 tests). (Tests exercise pure update/impulse; render and tap are covered via the game test in Task 7.)

- [ ] **Step 5: Commit**

```bash
git add lib/game/butterfly.dart test/butterfly_test.dart
git commit -m "add butterfly component"
```

---

## Task 7: FlutterGame core — TDD (depends on butterfly + flower + palette)

**Files:**
- Create: `lib/game/flutter_game.dart`
- Test: `test/flutter_game_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/flutter_game_test.dart
import 'package:flame_test/flame_test.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_acid/game/butterfly.dart';
import 'package:flutter_acid/game/flower.dart';
import 'package:flutter_acid/game/flutter_game.dart';

void main() {
  final tester = FlameTester(() => FlutterGame(seed: 7));

  tester.testGameWidget(
    'bloomFlowers adds flowers',
    verify: (game, _) async {
      final before = game.children.whereType<Flower>().length;
      game.bloomFlowers(3);
      await game.ready();
      expect(game.children.whereType<Flower>().length, before + 3);
    },
  );

  tester.testGameWidget(
    'onShake scatters, blooms, and shifts hue',
    verify: (game, _) async {
      await game.ready();
      final flowersBefore = game.children.whereType<Flower>().length;
      final hueBefore = game.hueOffset;
      final b = game.children.whereType<Butterfly>().first..velocity.setValues(1, 0);
      final speedBefore = b.velocity.length;
      game.onShake();
      await game.ready();
      expect(game.children.whereType<Flower>().length, greaterThan(flowersBefore));
      expect(game.hueOffset, isNot(hueBefore));
      expect(b.velocity.length, greaterThan(speedBefore));
    },
  );

  tester.testGameWidget(
    'catchButterfly increments counter and removes it',
    verify: (game, _) async {
      await game.ready();
      final b = game.children.whereType<Butterfly>().first;
      expect(game.caught.value, 0);
      game.catchButterfly(b);
      await game.ready();
      expect(game.caught.value, 1);
      expect(b.isMounted, isFalse);
    },
  );
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/flutter_game_test.dart`
Expected: FAIL — `FlutterGame` not defined.

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/game/flutter_game.dart
import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'butterfly.dart';
import 'flower.dart';
import 'motion.dart';
import 'palette.dart';

class FlutterGame extends FlameGame {
  FlutterGame({int seed = 0}) : _rng = math.Random(seed);

  final math.Random _rng;
  final ValueNotifier<int> caught = ValueNotifier<int>(0);
  double hueOffset = 0;

  static const int _initialButterflies = 8;
  static const int _initialFlowers = 4;

  @override
  Future<void> onLoad() async {
    for (var i = 0; i < _initialFlowers; i++) {
      add(_makeFlower());
    }
    for (var i = 0; i < _initialButterflies; i++) {
      add(_makeButterfly(i.toDouble()));
    }
  }

  Vector2 get _bounds => size.isZero() ? Vector2(400, 800) : size;

  Flower _makeFlower() => Flower(
        position: Vector2(_rng.nextDouble() * _bounds.x, _rng.nextDouble() * _bounds.y),
        hue: hueOffset,
      );

  Butterfly _makeButterfly(double seed) {
    final flowers = children.whereType<Flower>().toList();
    return Butterfly(
      position: Vector2(_rng.nextDouble() * _bounds.x, _rng.nextDouble() * _bounds.y),
      hue: hueOffset,
      seed: seed,
    )
      ..bounds = _bounds
      ..target = flowers.isEmpty ? null : flowers[_rng.nextInt(flowers.length)];
  }

  void scatter() {
    final center = _bounds / 2;
    for (final b in children.whereType<Butterfly>()) {
      b.applyImpulse(scatterImpulse(position: b.position, center: center, strength: 160));
    }
  }

  void bloomFlowers([int n = 3]) {
    for (var i = 0; i < n; i++) {
      add(_makeFlower());
    }
  }

  void shiftPalette([double degrees = 40]) {
    hueOffset = wrapHue(hueOffset + degrees);
    for (final b in children.whereType<Butterfly>()) {
      b.hue = hueOffset;
    }
    for (final f in children.whereType<Flower>()) {
      f.hue = hueOffset;
    }
  }

  void onShake() {
    scatter();
    bloomFlowers();
    shiftPalette();
  }

  void catchButterfly(Butterfly b) {
    if (b.caught) return;
    b.caught = true;
    caught.value += 1;
    b.removeFromParent();
    // Keep the scene alive: respawn after a short delay.
    add(
      TimerComponent(
        period: 1.5,
        removeOnFinish: true,
        onTick: () => add(_makeButterfly(caught.value.toDouble())),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/flutter_game_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/game/flutter_game.dart test/flutter_game_test.dart
git commit -m "add flutter game core"
```

---

## Task 8: ShakeDetector — TDD (independent)

**Files:**
- Create: `lib/input/shake_detector.dart`
- Test: `test/shake_detector_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/shake_detector_test.dart
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/shake_detector_test.dart`
Expected: FAIL — `ShakeDetector` not defined.

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/input/shake_detector.dart
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
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/shake_detector_test.dart`
Expected: PASS (3 tests).

> If `userAccelerometerEventStream` is not found, the installed `sensors_plus` uses the older API `userAccelerometerEvents` (a stream getter). Swap `userAccelerometerEventStream().listen` → `userAccelerometerEvents.listen`. Tests don't touch `start()`, so they stay green either way.

- [ ] **Step 5: Commit**

```bash
git add lib/input/shake_detector.dart test/shake_detector_test.dart
git commit -m "add shake detector"
```

---

## Task 9: HUD overlay — TDD (independent)

**Files:**
- Create: `lib/ui/hud.dart`
- Test: `test/hud_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/hud_test.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_acid/ui/hud.dart';

void main() {
  testWidgets('HUD shows the caught count and updates', (tester) async {
    final caught = ValueNotifier<int>(0);
    await tester.pumpWidget(MaterialApp(
      home: Hud(caught: caught, onShake: () {}),
    ));
    expect(find.text('0'), findsOneWidget);
    caught.value = 5;
    await tester.pump();
    expect(find.text('5'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/hud_test.dart`
Expected: FAIL — `Hud` not defined.

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/ui/hud.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Overlay HUD: caught counter (top-left) + debug-only shake button (bottom).
class Hud extends StatelessWidget {
  const Hud({super.key, required this.caught, required this.onShake});

  final ValueListenable<int> caught;
  final VoidCallback onShake;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🦋', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                ValueListenableBuilder<int>(
                  valueListenable: caught,
                  builder: (_, v, __) => Text(
                    '$v',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [Shadow(blurRadius: 8, color: Colors.black54)],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (kDebugMode)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: ElevatedButton.icon(
                  onPressed: onShake,
                  icon: const Icon(Icons.vibration),
                  label: const Text('Shake (debug)'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/hud_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/ui/hud.dart test/hud_test.dart
git commit -m "add hud overlay"
```

---

## Task 10: Tie-dye background (depends on FlutterGame existing)

**Files:**
- Create: `lib/game/tie_dye_background.dart`
- Modify: `lib/game/flutter_game.dart` (add background in `onLoad`, first child)
- Test: `test/tie_dye_background_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/tie_dye_background_test.dart
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/tie_dye_background_test.dart`
Expected: FAIL — `TieDyeBackground` not defined.

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/game/tie_dye_background.dart
import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'palette.dart';

/// Full-viewport swirling rainbow gradient.
class TieDyeBackground extends PositionComponent {
  TieDyeBackground() : super(priority: -1);

  double phase = 0;
  double hueOffset = 0;

  @override
  void update(double dt) => phase += dt * 0.15;

  @override
  void render(Canvas canvas) {
    final t = phase % 1.0;
    final a = Alignment(math.cos(t * 2 * math.pi), math.sin(t * 2 * math.pi));
    final colors = [for (final c in acidPalette) shiftHue(c, hueOffset)]
      ..add(shiftHue(acidPalette.first, hueOffset));
    final rect = Offset.zero & Size(size.x, size.y);
    final paint = Paint()
      ..shader = LinearGradient(
        begin: a,
        end: -a,
        colors: colors,
      ).createShader(rect);
    canvas.drawRect(rect, paint);
  }
}
```

- [ ] **Step 4: Wire it into the game (first child, tracks hue)**

In `lib/game/flutter_game.dart`: add `import 'tie_dye_background.dart';`, a field `late final TieDyeBackground _bg;`, and at the very start of `onLoad`:
```dart
_bg = TieDyeBackground()..size = _bounds;
add(_bg);
```
In `onGameResize(Vector2 size)` (override it), set `_bg.size = size;` and update each `Butterfly.bounds`. In `shiftPalette`, add `_bg.hueOffset = hueOffset;`.

- [ ] **Step 5: Run tests to verify they pass**

Run: `flutter test test/tie_dye_background_test.dart test/flutter_game_test.dart`
Expected: PASS (background test + the 3 game tests still green).

- [ ] **Step 6: Commit**

```bash
git add lib/game/tie_dye_background.dart lib/game/flutter_game.dart test/tie_dye_background_test.dart
git commit -m "add tie-dye background"
```

---

## Task 11: Wire main.dart + Simulator acceptance

**Files:**
- Modify: `lib/main.dart`
- Test: full suite + manual Simulator run

- [ ] **Step 1: Write `main.dart`**

```dart
// lib/main.dart
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'game/flutter_game.dart';
import 'input/shake_detector.dart';
import 'ui/hud.dart';

void main() {
  final game = FlutterGame();
  final detector = ShakeDetector(onShake: game.onShake)..start();
  runApp(FlutterApp(game: game, detector: detector));
}

class FlutterApp extends StatelessWidget {
  const FlutterApp({super.key, required this.game, required this.detector});
  final FlutterGame game;
  final ShakeDetector detector;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: GameWidget<FlutterGame>(
          game: game,
          overlayBuilderMap: {
            'hud': (_, g) => Hud(caught: g.caught, onShake: g.onShake),
          },
          initialActiveOverlays: const ['hud'],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Run the full test suite**

Run: `flutter test`
Expected: ALL tests pass.

- [ ] **Step 3: Analyze**

Run: `flutter analyze`
Expected: No issues (fix any lints).

- [ ] **Step 4: Manual Simulator acceptance**

Run:
```bash
flutter run -d "iPhone 15"
```
Confirm, in the Simulator:
1. Tie-dye background swirls; glowing butterflies drift toward glowing flowers.
2. Tapping a butterfly increments the 🦋 counter; a new one fades in shortly after.
3. The "Shake (debug)" button triggers scatter + new flowers + a hue shift across the scene.

Press `q` to quit.

- [ ] **Step 5: Commit**

```bash
git add lib/main.dart
git commit -m "wire game widget, hud, and shake detector"
```

---

## Self-Review notes (resolved)

- **Spec coverage:** concept (T6/7), visual style (T5/6/10), all 9 architecture files (T1–T11), ambient/tap/shake behaviors (T6/7), Simulator runnability + debug shake (T1/8/9/11), TDD across all logic (T3–T11). Covered.
- **Type consistency:** `onShake`, `scatter`, `bloomFlowers`, `shiftPalette`, `catchButterfly`, `caught` (ValueNotifier), `hueOffset`, `bounds`, `applyImpulse`, `phase` used consistently across tasks.
- **Known API caveat:** `sensors_plus` stream getter name (Task 8 note) and minor Flame `TapCallbacks`/`HasGameReference` naming may differ by version — tests are the guardrail; adjust imports if `flutter analyze` complains.
