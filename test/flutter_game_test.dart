import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_acid/game/butterfly.dart';
import 'package:flutter_acid/game/flower.dart';
import 'package:flutter_acid/game/flutter_game.dart';

void main() {
  testWithGame<FlutterGame>(
    'bloomFlowers adds flowers',
    () => FlutterGame(seed: 7),
    (game) async {
      final before = game.children.whereType<Flower>().length;
      game.bloomFlowers(3);
      await game.ready();
      expect(game.children.whereType<Flower>().length, before + 3);
    },
  );

  testWithGame<FlutterGame>(
    'onShake scatters, blooms, and shifts hue',
    () => FlutterGame(seed: 7),
    (game) async {
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

  testWithGame<FlutterGame>(
    'catchButterfly increments counter and removes it',
    () => FlutterGame(seed: 7),
    (game) async {
      final b = game.children.whereType<Butterfly>().first;
      expect(game.caught.value, 0);
      game.catchButterfly(b);
      await game.ready();
      expect(game.caught.value, 1);
      expect(b.isMounted, isFalse);
    },
  );
}
