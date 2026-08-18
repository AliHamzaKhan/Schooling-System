import 'package:flutter/material.dart';

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
    icon: Icons.notifications_active_outlined,
    features: [
      PlanFeature(
        key: 'notifications_push',
        label: 'Push notifications (Firebase)',
        description: 'In-app and device push via Firebase.',
        icon: Icons.phonelink_ring_outlined,
      ),
      PlanFeature(
        key: 'notifications_sms',
        label: 'SMS notifications (SIM)',
        description: 'Text-message alerts over a SIM gateway.',
        icon: Icons.sms_outlined,
      ),
      PlanFeature(
        key: 'notifications_whatsapp',
        label: 'WhatsApp notifications',
        description: 'Alerts delivered over WhatsApp.',
        icon: Icons.chat_outlined,
      ),
    ],
  ),
  PlanFeatureGroup(
    title: 'AI',
    icon: Icons.auto_awesome_outlined,
    features: [
      PlanFeature(
        key: 'ai_exam_generation',
        label: 'AI exam generation',
        description: 'Generate exams from course content.',
        icon: Icons.assignment_outlined,
      ),
      PlanFeature(
        key: 'ai_quiz_generation',
        label: 'AI quiz generation',
        description: 'Generate quizzes automatically.',
        icon: Icons.quiz_outlined,
      ),
    ],
  ),
  PlanFeatureGroup(
    title: 'Communication',
    icon: Icons.forum_outlined,
    features: [
      PlanFeature(
        key: 'two_way_messaging',
        label: 'Two-way messaging',
        description: 'Guardians and staff can reply, not just receive.',
        icon: Icons.swap_horiz_outlined,
      ),
    ],
  ),
  PlanFeatureGroup(
    title: 'Reporting',
    icon: Icons.insights_outlined,
    features: [
      PlanFeature(
        key: 'advanced_reports',
        label: 'Advanced reports & audit logs',
        description: 'Deeper analytics plus a full audit trail.',
        icon: Icons.fact_check_outlined,
      ),
    ],
  ),
  PlanFeatureGroup(
    title: 'Operations',
    icon: Icons.directions_bus_outlined,
    features: [
      PlanFeature(
        key: 'transport',
        label: 'Transport',
        description: 'Routes, vehicles, and pickup management.',
        icon: Icons.directions_bus_outlined,
      ),
    ],
  ),
  PlanFeatureGroup(
    title: 'Support',
    icon: Icons.support_agent_outlined,
    features: [
      PlanFeature(
        key: 'priority_support',
        label: 'Priority support',
        description: 'Faster response times and a dedicated channel.',
        icon: Icons.bolt_outlined,
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
