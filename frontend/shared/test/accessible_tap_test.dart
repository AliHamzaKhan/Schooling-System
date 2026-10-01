import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';

void main() {
  testWidgets('accessible tap is a focusable, keyboard-activated button', (tester) async {
    var taps = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AccessibleTap(onTap: () => taps++, child: const Text('Open report')),
      ),
    ));
    final semantics = tester.getSemantics(find.text('Open report'));
    expect(semantics.flagsCollection.isButton, isTrue);

    await tester.tap(find.text('Open report'));
    expect(taps, 1);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(taps, 2);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(taps, 3);
  });
}
