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
                  builder: (_, v, _) => Text(
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
