import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/teacher_repository.dart';
import '../../classes/models/my_class.dart';
import 'package:shared/shared.dart';

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
  push('push', 'Push notification', AppIcons.notificationsActiveOutlined),
  sms('sms', 'SMS', AppIcons.smsOutlined),
  whatsapp('whatsapp', 'WhatsApp', AppIcons.chatOutlined),
  email('email', 'Email', AppIcons.mailOutlineRounded);

  const AnnouncementChannel(this.wire, this.label, this.icon);
  final String wire;
  final String label;
  final IconData icon;
}

class CreateAnnouncementController extends GetxController {
  final TeacherRepository _repo;
  CreateAnnouncementController({TeacherRepository? repo})
      : _repo = repo ?? Get.find<TeacherRepository>();

  /// Field values. Their `TextEditingController`s are owned by
  /// [CreateAnnouncementView]'s State and disposed with that screen.
  final title = ''.obs;
  final body = ''.obs;

  final loadingSections = true.obs;
  final sections = <MyClass>[].obs;

  final audience = AnnouncementAudience.section.obs;
  final channel = AnnouncementChannel.push.obs;
  final sectionId = RxnString();

  final submitting = false.obs;
  final error = RxnString();
  BroadcastOutcome outcome = const BroadcastOutcome(null);

  @override
  void onInit() {
    super.onInit();
    final pending = _repo.pendingBroadcast;
    if (pending != null) {
      title.value = pending['title'] as String? ?? '';
      body.value = pending['body'] as String? ?? '';
      audience.value = AnnouncementAudience.values.firstWhere((a) => a.wire == pending['audience_type']);
      channel.value = AnnouncementChannel.values.firstWhere((c) => c.wire == pending['channel']);
      sectionId.value = pending['audience_ref'] as String?;
      error.value = 'Previous save unresolved. Retry this restored announcement unchanged.';
    }
    _loadSections();
  }

  Future<void> _loadSections() async {
    loadingSections.value = true;
    final res = await _repo.loadMyTimetable();
    if (res.success) {
      final mine = MyClass.fromSlots(res.data ?? const []);
      sections.assignAll(mine);
      if (mine.isNotEmpty && sectionId.value == null) sectionId.value = mine.first.sectionId;
    }
    loadingSections.value = false;
  }

  void selectAudience(AnnouncementAudience a) => audience.value = a;
  void selectChannel(AnnouncementChannel c) => channel.value = c;
  void selectSection(String? id) => sectionId.value = id;

  /// Returns true when saved; [outcome] describes delivery separately.
  Future<bool> submit() async {
    if (submitting.value) return false;
    error.value = null;
    final message = body.value.trim();
    if (message.isEmpty) {
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
      title: title.value.trim().isEmpty ? null : title.value.trim(),
      body: message,
    );
    submitting.value = false;

    if (!res.success) {
      error.value = res.error ?? 'Could not send the announcement.';
      return false;
    }
    outcome = BroadcastOutcome(res.rawJson?['status'] as String?);
    return true;
  }
}
