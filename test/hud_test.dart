import 'package:flutter/material.dart';
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
