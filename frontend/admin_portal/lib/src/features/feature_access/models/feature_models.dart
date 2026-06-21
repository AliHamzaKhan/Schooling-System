import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

/// A platform feature flag toggled from the Feature Access Control Panel.
class FeatureFlag {
  final String key;
  final String name;
  final String description;
  final bool enabled;
  final bool beta;

  const FeatureFlag({
    required this.key,
    required this.name,
    required this.description,
    required this.enabled,
    this.beta = false,
  });

  FeatureFlag copyWith({bool? enabled}) => FeatureFlag(
        key: key,
        name: name,
        description: description,
        enabled: enabled ?? this.enabled,
        beta: beta,
      );
}

/// A titled group of feature flags.
class FeatureModule {
  final String title;
  final IconData icon;
  final Color color;
  final List<FeatureFlag> features;

  const FeatureModule({
    required this.title,
    required this.icon,
    required this.color,
    required this.features,
  });

  FeatureModule copyWith({List<FeatureFlag>? features}) => FeatureModule(
        title: title,
        icon: icon,
        color: color,
        features: features ?? this.features,
      );
}

class FeatureAccessRepository {
  Future<ApiResponse<List<FeatureModule>>> load() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return ApiResponse.ok(_defaults());
  }

  static List<FeatureModule> _defaults() => const [
        FeatureModule(
          title: 'Communication',
          icon: Icons.forum_outlined,
          color: AppColors.primary,
          features: [
            FeatureFlag(
                key: 'chat',
                name: 'In-app Messaging',
                description: 'Teacher–guardian direct chat',
                enabled: true),
            FeatureFlag(
                key: 'video',
                name: 'Video Meetings',
                description: 'Built-in parent-teacher video calls',
                enabled: false,
                beta: true),
            FeatureFlag(
                key: 'announcements',
                name: 'Announcements',
                description: 'Broadcast notices to roles',
                enabled: true),
          ],
        ),
        FeatureModule(
          title: 'Academics',
          icon: Icons.menu_book_outlined,
          color: AppColors.tertiary,
          features: [
            FeatureFlag(
                key: 'online_exams',
                name: 'Online Exams',
                description: 'Conduct and grade exams in-app',
                enabled: true),
            FeatureFlag(
                key: 'ai_insights',
                name: 'AI Performance Insights',
                description: 'Automated progress summaries',
                enabled: false,
                beta: true),
          ],
        ),
        FeatureModule(
          title: 'Finance',
          icon: Icons.payments_outlined,
          color: Color(0xFFE8A317),
          features: [
            FeatureFlag(
                key: 'online_payments',
                name: 'Online Fee Payments',
                description: 'Card / wallet collection',
                enabled: true),
            FeatureFlag(
                key: 'installments',
                name: 'Installment Plans',
                description: 'Split fees into scheduled payments',
                enabled: false),
          ],
        ),
      ];
}
