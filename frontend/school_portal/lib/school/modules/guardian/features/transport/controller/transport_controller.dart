import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../services/location_service.dart';
import '../../../../../widgets/action_form_sheet.dart';
import '../../../data/guardian_repository.dart';
import '../../../shared/controller/guardian_session_controller.dart';
import '../models/transport_models.dart';

/// Guardian transport: raise a pickup request for the selected child and track
/// their bus while a trip is active.
class GuardianTransportController extends GetxController {
  final GuardianRepository _repo;
  final GuardianSessionController _session;
  final LocationService _location;
  GuardianTransportController({
    GuardianRepository? repo,
    GuardianSessionController? session,
    LocationService? location,
  })  : _repo = repo ?? Get.find<GuardianRepository>(),
        _session = session ?? Get.find<GuardianSessionController>(),
        _location = location ?? const LocationService();

  final loading = true.obs;
  final error = RxnString();
  final requests = <MyTransportRequest>[].obs;
  final trips = <ActiveTrip>[].obs;
  final location = Rxn<TripLocation>();
  final eta = Rxn<TripEta>();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    final reqRes = await _repo.loadMyTransportRequests();
    if (reqRes.success && reqRes.data != null) {
      requests.assignAll(reqRes.data!);
    } else {
      error.value = reqRes.error ?? 'Could not load transport requests.';
    }
    final tripRes = await _repo.loadActiveTrips();
    if (tripRes.success && tripRes.data != null) {
      trips.assignAll(tripRes.data!);
      if (trips.isNotEmpty) await refreshTracking(trips.first.id);
    }
    loading.value = false;
  }

  Future<void> refreshTracking(String tripId) async {
    final loc = await _repo.loadTripLocation(tripId);
    location.value = loc.success ? loc.data : null;
    final e = await _repo.loadTripEta(tripId);
    eta.value = e.success ? e.data : null;
  }

  Future<void> raiseRequestFlow() async {
    final childId = _session.selectedId.value;
    if (childId == null) {
      Get.snackbar('Select a child', 'Choose a child before requesting transport.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    double? lat;
    double? lng;
    final address = TextEditingController();
    final notes = TextEditingController();
    try {
      final picked = await _location.capture();
      lat = picked.latitude;
      lng = picked.longitude;
      if (picked.address != null) address.text = picked.address!;
    } on LocationException catch (e) {
      Get.snackbar('Location', '${e.message} You can type the address instead.',
          snackPosition: SnackPosition.BOTTOM);
    } catch (_) {
      // Non-fatal — manual address entry still works.
    }

    final ok = await showActionFormSheet(
      title: 'Request Transport',
      submitLabel: 'Send request',
      ownedControllers: [address, notes],
      fields: [
        GlassInput(
          label: 'Pickup address',
          hint: 'Where should the bus pick up your child?',
          controller: address,
        ),
        GlassInput(
          label: 'Notes (optional)',
          hint: 'Landmark, timing, etc.',
          controller: notes,
        ),
        if (lat != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text('Location captured ✓',
                style: AppTypography.labelMd.copyWith(color: AppColors.primary)),
          ),
      ],
      onSubmit: () async {
        if (address.text.trim().isEmpty) return 'Enter a pickup address';
        final res = await _repo.createTransportRequest(
          studentId: childId,
          pickupAddress: address.text.trim(),
          latitude: lat,
          longitude: lng,
          notes: notes.text.trim().isEmpty ? null : notes.text.trim(),
        );
        return res.success ? null : (res.error ?? 'Could not send request');
      },
    );
    if (ok == true) {
      Get.snackbar('Request sent', 'The school will review it shortly.',
          snackPosition: SnackPosition.BOTTOM);
      await load();
    }
  }
}
