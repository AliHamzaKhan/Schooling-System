import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../widgets/action_form_sheet.dart';
import '../../../data/headmaster_repository.dart';
import '../models/announcement.dart';

/// Drives the Announcements Hub: filter + list state, with a "compose" hook.
class AnnouncementsController extends GetxController {
  final HeadmasterRepository _repo;
  AnnouncementsController({HeadmasterRepository? repo})
      : _repo = repo ?? Get.find<HeadmasterRepository>();

  static const filters = ['All Updates', 'School-Wide', 'Teachers Only', 'Events'];

  final loading = true.obs;
  final error = RxnString();
  final items = <Announcement>[].obs;
  final filter = 'All Updates'.obs;

  @override
  void onInit() {
    super.onInit();
    fetch();
  }

  void selectFilter(String value) {
    if (filter.value == value) return;
    filter.value = value;
    fetch();
  }

  Future<void> fetch() async {
    loading.value = true;
    error.value = null;
    final res = await _repo.loadAnnouncements(filter: filter.value);
    if (res.success && res.data != null) {
      items.assignAll(res.data!);
    } else {
      error.value = res.error ?? 'Could not load announcements.';
    }
    loading.value = false;
  }

  /// Backend `AudienceType` value → human label for the audience picker.
  static const _audiences = {
    'entire_school': 'School-Wide',
    'teachers': 'Teachers',
    'guardians': 'Guardians',
    'students': 'Students',
  };

  /// Opens the compose form and posts a new broadcast; reloads the feed on
  /// success.
  Future<void> composeFlow() async {
    final title = TextEditingController();
    final body = TextEditingController();
    final audience = 'entire_school'.obs;

    final ok = await showActionFormSheet(
      title: 'New Announcement',
      submitLabel: 'Publish',
      fields: [
        GlassInput(
            label: 'Title', hint: 'Optional headline', controller: title),
        GlassInput(
          label: 'Message',
          hint: 'What would you like to announce?',
          controller: body,
          keyboardType: TextInputType.multiline,
        ),
        Obx(() => ActionDropdownField<String>(
              label: 'Audience',
              hint: 'Who should see this?',
              value: audience.value,
              items: [
                for (final e in _audiences.entries)
                  DropdownMenuItem(value: e.key, child: Text(e.value)),
              ],
              onChanged: (v) => audience.value = v ?? 'entire_school',
            )),
      ],
      onSubmit: () async {
        if (body.text.trim().isEmpty) return 'A message is required';
        final res = await _repo.createBroadcast(
          body: body.text.trim(),
          title: title.text.trim().isEmpty ? null : title.text.trim(),
          audienceType: audience.value,
        );
        return res.success
            ? null
            : (res.error ?? 'Could not publish the announcement');
      },
    );
    if (ok == true) {
      Get.snackbar('Announcement published', 'Your announcement was sent.',
          snackPosition: SnackPosition.BOTTOM);
      await fetch();
    }
  }
}
