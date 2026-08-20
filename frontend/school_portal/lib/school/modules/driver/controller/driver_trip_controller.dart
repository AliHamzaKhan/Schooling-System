import 'dart:async';

import 'package:get/get.dart';

import '../../../services/location_service.dart';
import '../data/driver_models.dart';
import '../data/driver_repository.dart';

/// Drives the Driver's single screen: pick a route and start today's trip, work
/// the optimized manifest (next-destination header + reorder + board/absent/
/// drop), and publish the device location every minute while the trip runs.
class DriverTripController extends GetxController {
  final DriverRepository _repo;
  final LocationService _location;
  DriverTripController({DriverRepository? repo, LocationService? location})
      : _repo = repo ?? Get.find<DriverRepository>(),
        _location = location ?? const LocationService();

  static const _pingInterval = Duration(minutes: 1);

  final loading = true.obs;
  final error = RxnString();
  final busy = false.obs;

  final assignments = <DriverAssignment>[].obs;
  final _routeNames = <String, String>{}.obs;
  final trip = Rxn<DriverTrip>();

  /// Trip-type toggle for the start form.
  final tripType = 'pickup'.obs;
  final selectedRouteId = RxnString();

  Timer? _pingTimer;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  @override
  void onClose() {
    _pingTimer?.cancel();
    super.onClose();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;

    final asgRes = await _repo.loadMyAssignments();
    if (asgRes.success && asgRes.data != null) {
      assignments.assignAll(asgRes.data!);
    } else {
      error.value = asgRes.error ?? 'Could not load your assignments.';
    }

    final routeRes = await _repo.loadRoutes();
    if (routeRes.success && routeRes.data != null) {
      _routeNames.assignAll({for (final r in routeRes.data!) r.id: r.name});
    }

    // Resume an in-progress trip if one exists.
    final activeRes = await _repo.loadActiveTrips();
    if (activeRes.success && activeRes.data != null && activeRes.data!.isNotEmpty) {
      trip.value = activeRes.data!.first;
      _startPinging();
    }

    selectedRouteId.value ??=
        routeOptions.isNotEmpty ? routeOptions.first.id : null;
    loading.value = false;
  }

  /// Distinct routes the driver is actually assigned to, with display names.
  List<DriverRouteOption> get routeOptions {
    final ids = <String>{for (final a in assignments) a.routeId};
    return [
      for (final id in ids)
        DriverRouteOption(id: id, name: _routeNames[id] ?? 'Route'),
    ];
  }

  String routeName(String routeId) => _routeNames[routeId] ?? 'Route';

  /// The pickup address for a student (from their assignment), used as the stop
  /// label on the manifest.
  String stopLabel(String studentId) {
    final a = assignments.firstWhereOrNull((a) => a.studentId == studentId);
    return a?.address?.trim().isNotEmpty == true ? a!.address! : 'Stop';
  }

  // ------------------------------ lifecycle ---------------------------- #

  Future<void> startTrip() async {
    final routeId = selectedRouteId.value;
    if (routeId == null) {
      Get.snackbar('No route', 'You have no assigned route to start.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    busy.value = true;
    final res = await _repo.startTrip(routeId: routeId, tripType: tripType.value);
    busy.value = false;
    if (res.success && res.data != null) {
      trip.value = res.data;
      _startPinging();
    } else {
      Get.snackbar('Could not start', res.error ?? 'Please try again.',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> endTrip() async {
    final t = trip.value;
    if (t == null) return;
    busy.value = true;
    final res = await _repo.endTrip(t.id);
    busy.value = false;
    if (res.success) {
      _stopPinging();
      trip.value = null;
      Get.snackbar('Trip ended', 'Nice work — the trip is complete.',
          snackPosition: SnackPosition.BOTTOM);
    } else {
      Get.snackbar('Could not end trip', res.error ?? 'Please try again.',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> setStatus(String studentId, String status) async {
    final t = trip.value;
    if (t == null) return;
    final res = await _repo.setStudentStatus(
        tripId: t.id, studentId: studentId, status: status);
    if (res.success && res.data != null) {
      trip.value = res.data;
    } else {
      Get.snackbar('Could not update', res.error ?? 'Please try again.',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  /// Persist a manual drag-reorder of the manifest to the active trip.
  Future<void> reorder(int oldIndex, int newIndex) async {
    final t = trip.value;
    if (t == null) return;
    final order = List<String>.from(t.stopOrder);
    if (newIndex > oldIndex) newIndex -= 1;
    final moved = order.removeAt(oldIndex);
    order.insert(newIndex, moved);
    // Optimistic local update, then persist.
    trip.value = DriverTrip(
      id: t.id, routeId: t.routeId, tripType: t.tripType, status: t.status,
      stopOrder: order, nextStudentId: t.nextStudentId, events: t.events,
    );
    final res = await _repo.updateStopOrder(t.id, order);
    if (res.success && res.data != null) {
      trip.value = res.data;
    } else {
      Get.snackbar('Could not reorder', res.error ?? 'Please try again.',
          snackPosition: SnackPosition.BOTTOM);
      await refreshTrip();
    }
  }

  Future<void> refreshTrip() async {
    final t = trip.value;
    if (t == null) return;
    final res = await _repo.loadTrip(t.id);
    if (res.success && res.data != null) trip.value = res.data;
  }

  // --------------------------- location pings -------------------------- #

  void _startPinging() {
    _pingTimer?.cancel();
    _sendPing(); // immediate first fix
    _pingTimer = Timer.periodic(_pingInterval, (_) => _sendPing());
  }

  void _stopPinging() {
    _pingTimer?.cancel();
    _pingTimer = null;
  }

  Future<void> _sendPing() async {
    final t = trip.value;
    if (t == null || !t.inProgress) return;
    try {
      final picked = await _location.capture();
      await _repo.postLocation(
        tripId: t.id,
        latitude: picked.latitude,
        longitude: picked.longitude,
        address: picked.address,
      );
    } catch (_) {
      // Best-effort — a missed fix (no signal / permission) is retried next tick.
    }
  }
}
