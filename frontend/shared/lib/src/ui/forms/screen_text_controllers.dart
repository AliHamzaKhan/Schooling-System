import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

/// Gives a screen ownership of its own [TextEditingController]s.
///
/// Every `TextField`/`TextFormField` must be driven by a controller created by,
/// and disposed with, the [State] that builds it. Keeping them on a
/// [GetxController] instead makes their lifetime GetX's: a lazily-registered
/// controller is dropped when its route pops (and rebuilt fresh when `fenix` is
/// set), so a still-mounted screen can end up holding a controller that was
/// already disposed — "A TextEditingController was used after being disposed" —
/// or two screens can end up sharing one field.
///
/// Mix this into the screen's [State] and create fields with [textController]
/// or [boundController]; disposal is handled here.
///
/// ```dart
/// class _FooViewState extends State<FooView> with ScreenTextControllers {
///   final c = Get.find<FooController>();
///   late final _title = boundController(c.title);
///   late final _note = textController(initialText: 'draft');
/// }
/// ```
mixin ScreenTextControllers<T extends StatefulWidget> on State<T> {
  final List<TextEditingController> _ownedControllers = [];
  final List<Worker> _boundWorkers = [];

  /// A controller owned by this screen. Disposed automatically.
  TextEditingController textController({String initialText = ''}) {
    final controller = TextEditingController(text: initialText);
    _ownedControllers.add(controller);
    return controller;
  }

  /// A controller owned by this screen and two-way bound to [source] — the
  /// plain value a [GetxController] keeps for validation and submission.
  ///
  /// Typing pushes into [source]; changes made to [source] elsewhere (an async
  /// prefill, a reset after submit) push back into the field.
  TextEditingController boundController(RxString source) {
    final controller = textController(initialText: source.value);
    controller.addListener(() => source.value = controller.text);
    _boundWorkers.add(ever<String>(source, (value) {
      if (controller.text != value) controller.text = value;
    }));
    return controller;
  }

  /// Disposes a controller this screen no longer needs — for fields that come
  /// and go while the screen is alive, such as a growing list of rows.
  void disposeTextController(TextEditingController controller) {
    if (_ownedControllers.remove(controller)) controller.dispose();
  }

  @override
  void dispose() {
    for (final worker in _boundWorkers) {
      worker.dispose();
    }
    for (final controller in _ownedControllers) {
      controller.dispose();
    }
    _boundWorkers.clear();
    _ownedControllers.clear();
    super.dispose();
  }
}
