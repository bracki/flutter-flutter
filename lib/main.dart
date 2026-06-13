// lib/main.dart
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'game/flutter_game.dart';
import 'input/shake_detector.dart';
import 'ui/hud.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
