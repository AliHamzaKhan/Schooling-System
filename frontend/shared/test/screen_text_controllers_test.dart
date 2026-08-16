import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

/// Stand-in for the value a GetX controller keeps for a field.
class _Model {
  final text = ''.obs;
}

class _Form extends StatefulWidget {
  final _Model model;
  const _Form({required this.model});

  @override
  State<_Form> createState() => _FormState();
}

class _FormState extends State<_Form> with ScreenTextControllers {
  late final controller = boundController(widget.model.text);

  /// Exposed so the test can assert the controller is disposed with the screen.
  TextEditingController get fieldController => controller;

  @override
  Widget build(BuildContext context) => MaterialApp(
        home: Scaffold(body: TextField(controller: controller)),
      );
}

void main() {
  testWidgets('typing flows into the bound value', (tester) async {
    final model = _Model();
    await tester.pumpWidget(_Form(model: model));

    await tester.enterText(find.byType(TextField), 'ada@school.edu');
    expect(model.text.value, 'ada@school.edu');
  });

  testWidgets('a value set elsewhere flows back into the field',
      (tester) async {
    final model = _Model();
    await tester.pumpWidget(_Form(model: model));

    // e.g. restored credentials, or a form reset after submitting.
    model.text.value = 'restored@school.edu';
    await tester.pump();

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, 'restored@school.edu');
  });

  testWidgets('the field starts from the value already on the model',
      (tester) async {
    final model = _Model();
    model.text.value = 'prefilled@school.edu';
    await tester.pumpWidget(_Form(model: model));

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, 'prefilled@school.edu');
  });

  testWidgets('the controller is disposed with the screen', (tester) async {
    final model = _Model();
    await tester.pumpWidget(_Form(model: model));
    final state = tester.state<_FormState>(find.byType(_Form));
    final controller = state.fieldController;

    // Unmount the screen, as popping its route would.
    await tester.pumpWidget(const SizedBox.shrink());

    // Using a disposed controller throws — this is the failure mode the
    // refactor exists to prevent, so assert it happens exactly at unmount.
    expect(() => controller.addListener(() {}), throwsFlutterError);

    // And the binding is severed: later value changes must not touch it.
    expect(() => model.text.value = 'after dispose', returnsNormally);
  });
}
