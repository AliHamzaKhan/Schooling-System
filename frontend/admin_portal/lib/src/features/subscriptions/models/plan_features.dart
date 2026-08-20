import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

/// A single admin-togglable plan feature. Its [key] is what gets stored in the
/// plan's `modules` array on the backend; the rest is presentation only.
class PlanFeature {
  final String key;
  final String label;
  final String description;
  final IconData icon;

  const PlanFeature({
    required this.key,
    required this.label,
    required this.description,
    required this.icon,
  });
}

/// A titled group of related features, rendered as one section on the plan form.
class PlanFeatureGroup {
  final String title;
  final IconData icon;
  final List<PlanFeature> features;

  const PlanFeatureGroup({
    required this.title,
    required this.icon,
    required this.features,
  });
}

/// The catalog of add-on features an admin can attach to a subscription plan.
///
/// Each feature's [PlanFeature.key] is persisted inside the plan's `modules`
/// list (the backend accepts arbitrary module strings), so toggling a checkbox
/// simply adds or removes its key.
const List<PlanFeatureGroup> kPlanFeatureGroups = [
  PlanFeatureGroup(
    title: 'Notifications',
    icon: AppIcons.notificationsActiveOutlined,
    features: [
      PlanFeature(
        key: 'notifications_push',
        label: 'Push notifications (Firebase)',
        description: 'In-app and device push via Firebase.',
        icon: AppIcons.phonelinkRingOutlined,
      ),
      PlanFeature(
        key: 'notifications_sms',
        label: 'SMS notifications (SIM)',
        description: 'Text-message alerts over a SIM gateway.',
        icon: AppIcons.smsOutlined,
      ),
      PlanFeature(
        key: 'notifications_whatsapp',
        label: 'WhatsApp notifications',
        description: 'Alerts delivered over WhatsApp.',
        icon: AppIcons.chatOutlined,
      ),
    ],
  ),
  PlanFeatureGroup(
    title: 'AI',
    icon: AppIcons.autoAwesomeOutlined,
    features: [
      PlanFeature(
        key: 'ai_exam_generation',
        label: 'AI exam generation',
        description: 'Generate exams from course content.',
        icon: AppIcons.assignmentOutlined,
      ),
      PlanFeature(
        key: 'ai_quiz_generation',
        label: 'AI quiz generation',
        description: 'Generate quizzes automatically.',
        icon: AppIcons.quizOutlined,
      ),
    ],
  ),
  PlanFeatureGroup(
    title: 'Communication',
    icon: AppIcons.forumOutlined,
    features: [
      PlanFeature(
        key: 'two_way_messaging',
        label: 'Two-way messaging',
        description: 'Guardians and staff can reply, not just receive.',
        icon: AppIcons.swapHorizOutlined,
      ),
    ],
  ),
  PlanFeatureGroup(
    title: 'Reporting',
    icon: AppIcons.insightsOutlined,
    features: [
      PlanFeature(
        key: 'advanced_reports',
        label: 'Advanced reports & audit logs',
        description: 'Deeper analytics plus a full audit trail.',
        icon: AppIcons.factCheckOutlined,
      ),
    ],
  ),
  PlanFeatureGroup(
    title: 'Operations',
    icon: AppIcons.directionsBusOutlined,
    features: [
      PlanFeature(
        key: 'transport',
        label: 'Transport',
        description: 'Routes, vehicles, and pickup management.',
        icon: AppIcons.directionsBusOutlined,
      ),
    ],
  ),
  PlanFeatureGroup(
    title: 'Support',
    icon: AppIcons.supportAgentOutlined,
    features: [
      PlanFeature(
        key: 'priority_support',
        label: 'Priority support',
        description: 'Faster response times and a dedicated channel.',
        icon: AppIcons.boltOutlined,
      ),
    ],
  ),
];

/// Flat list of every feature key in the catalog (used to label a plan's
/// enabled add-ons without walking the group tree).
final Map<String, PlanFeature> kPlanFeatureByKey = {
  for (final g in kPlanFeatureGroups)
    for (final f in g.features) f.key: f,
};
