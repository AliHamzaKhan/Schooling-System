import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';

Color? _ringColor(WidgetTester tester, Finder button) {
  final box = tester.widget<DecoratedBox>(
    find.descendant(of: find.byType(FocusRing).first, matching: find.byType(DecoratedBox)).first,
  );
  return ((box.decoration as BoxDecoration).border as Border).top.color;
}

void main() {
  testWidgets('primary and ghost buttons show a ring only under keyboard focus', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Column(children: [
          PrimaryButton(label: 'Save', onPressed: () {}),
          GhostButton(label: 'Cancel', onPressed: () {}),
        ]),
      ),
    ));
    final primary = find.byType(PrimaryButton);
    expect(_ringColor(tester, primary), Colors.transparent);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(FocusManager.instance.highlightMode, FocusHighlightMode.traditional);
    expect(_ringColor(tester, primary), AppColors.onSurface);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(_ringColor(tester, primary), Colors.transparent);
    final ghostRing = tester.widget<DecoratedBox>(
      find.descendant(of: find.byType(FocusRing).last, matching: find.byType(DecoratedBox)).first,
    );
    expect(((ghostRing.decoration as BoxDecoration).border as Border).top.color, AppColors.onSurface);
  });
}
