/// Public API of the `shared` package — common design system, services and
/// cross-portal features for the school & admin portals.
///
/// Heavier modules under `lib/src` (notifications, biometric, permissions,
/// version) are intentionally NOT exported here yet: they pull in firebase/
/// etc. Export them once their dependencies are added to `pubspec.yaml` and
/// the modules are actually used.
library;

export 'src/notifications/broadcast_outcome.dart';

export 'src/services/payment_retry_guard.dart';

export 'src/services/attachment_access_service.dart';

// ── Design tokens ───────────────────────────────────────────────
export 'src/ui/tokens/app_colors.dart';
export 'src/ui/tokens/app_typography.dart';
export 'src/ui/tokens/app_spacing.dart';
export 'src/ui/tokens/app_radius.dart';
export 'src/ui/tokens/app_elevation.dart';

// ── Iconography (Font Awesome, single source of truth) ──────────
export 'src/assets/app_icons.dart';

// ── Theme / layout / responsive ─────────────────────────────────
export 'src/ui/theme/app_theme.dart';
export 'src/ui/layout/app_scaffold.dart';
export 'src/ui/responsive/breakpoints.dart';

// ── Animations ──────────────────────────────────────────────────
export 'src/ui/anim/app_motion.dart';
export 'src/ui/anim/fade_slide_in.dart';
export 'src/ui/anim/pressable.dart';
export 'src/ui/anim/shimmer.dart';

// ── Widgets ─────────────────────────────────────────────────────
export 'src/ui/forms/screen_text_controllers.dart';

export 'src/ui/widgets/primary_button.dart';
export 'src/ui/widgets/ghost_button.dart';
export 'src/ui/widgets/app_dialog.dart';
export 'src/ui/widgets/app_card.dart';
export 'src/ui/widgets/app_data_table.dart';
export 'src/ui/widgets/app_state_view.dart';
export 'src/ui/widgets/app_text_field.dart';
export 'src/ui/widgets/glass_surface.dart';
export 'src/ui/widgets/glass_input.dart';
export 'src/ui/widgets/glass_fab.dart';
export 'src/ui/widgets/area_chart.dart';
export 'src/ui/widgets/ai_insight_chip.dart';
export 'src/ui/widgets/step_badge.dart';

// ── Services ────────────────────────────────────────────────────
export 'src/services/http_method.dart';
export 'src/services/api_response.dart';
export 'src/services/api_exception.dart';
export 'src/services/api_service.dart';
export 'src/services/auth_service.dart';
export 'src/services/data_store_service.dart';
export 'src/services/data_parser_service.dart';
export 'src/services/datetime_parser_service.dart';
export 'src/services/settings_api.dart';

// ── Environment ─────────────────────────────────────────────────
export 'src/env/environment.dart';
export 'src/env/env_config.dart';

// ── App bootstrap ───────────────────────────────────────────────
export 'src/app/services_bootstrap.dart';

// ── Messaging feature (two-way direct messages, all portals) ────
export 'src/features/messaging/models/direct_message.dart';
export 'src/features/messaging/models/conversation.dart';
export 'src/features/messaging/models/messaging_contact.dart';
export 'src/features/messaging/data/messaging_service.dart';
export 'src/features/messaging/controller/inbox_controller.dart';
export 'src/features/messaging/controller/conversation_controller.dart';
export 'src/features/messaging/controller/new_message_controller.dart';
export 'src/features/messaging/view/inbox_view.dart';
export 'src/features/messaging/view/conversation_view.dart';
export 'src/features/messaging/view/new_message_sheet.dart';

// ── Auth feature (login / forgot / verify OTP / reset) ──────────
export 'src/features/auth/auth_config.dart';
export 'src/features/auth/auth_routes.dart';
export 'src/features/auth/role_route_guard.dart';
export 'src/features/auth/models/institution.dart';
export 'src/features/auth/models/password_strength.dart';
export 'src/services/broadcast_retry_guard.dart';

export 'src/features/auth/view/sessions_view.dart';

export 'src/features/auth/session_navigation.dart';
export 'src/features/auth/view/route_context_missing_view.dart';
