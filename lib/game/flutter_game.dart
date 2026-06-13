import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'butterfly.dart';
import 'flower.dart';
import 'motion.dart';
import 'palette.dart';
import 'tie_dye_background.dart';

class FlutterGame extends FlameGame {
  FlutterGame({int seed = 0}) : _rng = math.Random(seed);

  final math.Random _rng;
  final ValueNotifier<int> caught = ValueNotifier<int>(0);
  double hueOffset = 0;
  late final TieDyeBackground _bg;

  static const int _initialButterflies = 8;
  static const int _initialFlowers = 4;

  @override
  Future<void> onLoad() async {
    _bg = TieDyeBackground()..size = _bounds;
    add(_bg);
    for (var i = 0; i < _initialFlowers; i++) {
      add(_makeFlower());
    }
    for (var i = 0; i < _initialButterflies; i++) {
      add(_makeButterfly(i.toDouble()));
    }
  }

  Vector2 get _bounds => (size.x == 0 || size.y == 0) ? Vector2(400, 800) : size;

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (isLoaded) {
      _bg.size = size;
      for (final b in children.whereType<Butterfly>()) {
        b.bounds = size;
      }
    }
  }

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
    _bg.hueOffset = hueOffset;
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
    add(
      TimerComponent(
        period: 1.5,
        removeOnFinish: true,
        onTick: () => add(_makeButterfly(caught.value.toDouble())),
      ),
    );
  }
}
