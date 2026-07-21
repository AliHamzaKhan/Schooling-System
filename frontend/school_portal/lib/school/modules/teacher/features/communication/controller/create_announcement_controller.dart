import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/teacher_repository.dart';
import '../../classes/models/my_class.dart';

/// Who an announcement goes to. Maps onto the backend's `AudienceType`.
enum AnnouncementAudience {
  section('section', 'One of my sections'),
  guardians('guardians', 'All guardians'),
  students('students', 'All students');

  const AnnouncementAudience(this.wire, this.label);
  final String wire;
  final String label;
}

/// Channel the message is delivered over. Maps onto the backend's `Channel`.
enum AnnouncementChannel {
  push('push', 'Push notification', Icons.notifications_active_outlined),
  sms('sms', 'SMS', Icons.sms_outlined),
  whatsapp('whatsapp', 'WhatsApp', Icons.chat_outlined),
  email('email', 'Email', Icons.mail_outline_rounded);

  const AnnouncementChannel(this.wire, this.label, this.icon);
  final String wire;
  final String label;
  final IconData icon;
}

class CreateAnnouncementController extends GetxController {
  final TeacherRepository _repo;
  CreateAnnouncementController({TeacherRepository? repo})
      : _repo = repo ?? Get.find<TeacherRepository>();

  final titleCtrl = TextEditingController();
  final bodyCtrl = TextEditingController();

  final loadingSections = true.obs;
  final sections = <MyClass>[].obs;

  final audience = AnnouncementAudience.section.obs;
  final channel = AnnouncementChannel.push.obs;
  final sectionId = RxnString();

  final submitting = false.obs;
  final error = RxnString();

  @override
  void onInit() {
    super.onInit();
    _loadSections();
  }

  @override
  void onClose() {
    titleCtrl.dispose();
    bodyCtrl.dispose();
    super.onClose();
  }

  Future<void> _loadSections() async {
    loadingSections.value = true;
    final res = await _repo.loadMyTimetable();
    if (res.success) {
      final mine = MyClass.fromSlots(res.data ?? const []);
      sections.assignAll(mine);
      if (mine.isNotEmpty) sectionId.value = mine.first.sectionId;
    }
    loadingSections.value = false;
  }

  void selectAudience(AnnouncementAudience a) => audience.value = a;
  void selectChannel(AnnouncementChannel c) => channel.value = c;
  void selectSection(String? id) => sectionId.value = id;

  /// Validates and publishes. Returns true when the announcement was sent.
  Future<bool> submit() async {
    error.value = null;
    final body = bodyCtrl.text.trim();
    if (body.isEmpty) {
      error.value = 'Write a message before sending.';
      return false;
    }
    final targetingSection = audience.value == AnnouncementAudience.section;
    if (targetingSection && sectionId.value == null) {
      error.value = 'Pick a section to send to.';
      return false;
    }

    submitting.value = true;
    final res = await _repo.createBroadcast(
      channel: channel.value.wire,
      audienceType: audience.value.wire,
      audienceRef: targetingSection ? sectionId.value : null,
      title: titleCtrl.text.trim().isEmpty ? null : titleCtrl.text.trim(),
      body: body,
    );
    submitting.value = false;

    if (!res.success) {
      error.value = res.error ?? 'Could not send the announcement.';
      return false;
    }
    return true;
  }
}
