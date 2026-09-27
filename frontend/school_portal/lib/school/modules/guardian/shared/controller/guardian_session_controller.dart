import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../models/child.dart';
import '../../data/guardian_repository.dart';

/// Module-wide session state for the Guardian portal. Holds the guardian's
/// children and the currently selected child — the single source of truth for
/// the multi-child switcher. Every feature controller reads [selectedChildId]
/// to scope its data to the active child.
///
/// Registered permanently in [GuardianSessionBinding] so it survives tab
/// switches and drill-in navigation.
class GuardianSessionController extends GetxController {
  final GuardianRepository _repo;
  GuardianSessionController({GuardianRepository? repo})
    : _repo = repo ?? Get.find<GuardianRepository>();

  final loading = true.obs;
  final children = <Child>[].obs;
  final selectedId = RxnString();
  final error = RxnString();
  Worker? _accountWorker;
  int _generation = 0;

  /// The active child, or null while loading / if the guardian has none.
  Child? get selected {
    final id = selectedId.value;
    if (id == null) return null;
    return children.firstWhereOrNull((c) => c.id == id);
  }

  bool get hasMultiple => children.length > 1;

  @override
  void onInit() {
    super.onInit();
    if (Get.isRegistered<AuthService>()) {
      final auth = Get.find<AuthService>();
      _accountWorker = ever(auth.currentUser, (_) {
        ++_generation;
        children.clear();
        selectedId.value = null;
        error.value = null;
        if (auth.roleCodes.contains('guardian')) load();
      });
    }
    load();
  }

  @override
  void onClose() {
    ++_generation;
    _accountWorker?.dispose();
    super.onClose();
  }

  Future<void> load() async {
    final generation = ++_generation;
    loading.value = true;
    error.value = null;
    children.clear();
    selectedId.value = null;
    final res = await _repo.loadChildren();
    if (generation != _generation || isClosed) return;
    if (res.success && res.data != null) {
      children.assignAll(res.data!);
      selectedId.value = children.isNotEmpty ? children.first.id : null;
    } else {
      error.value = res.error ?? 'Could not load linked children.';
    }
    loading.value = false;
  }

  /// Switch the active child. Feature controllers listen on [selectedId] (via
  /// `ever`) to reload their data.
  void select(String childId) {
    if (children.any((c) => c.id == childId)) {
      selectedId.value = childId;
    }
  }
}
