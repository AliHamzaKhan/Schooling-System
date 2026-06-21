import 'package:flutter/material.dart';

/// Single source of truth for iconography.
///
/// Reference these semantic names instead of `Icons.*` directly, so swapping an
/// icon (or a whole icon set) happens in one place and propagates everywhere.
class AppIcons {
  AppIcons._();

  // ── Brand / chrome ──────────────────────────────────────────
  static const IconData brand = Icons.favorite_rounded;
  static const IconData notifications = Icons.notifications_none_rounded;
  static const IconData back = Icons.arrow_back_rounded;
  static const IconData close = Icons.close_rounded;
  static const IconData chevronRight = Icons.chevron_right_rounded;
  static const IconData menu = Icons.menu_rounded;
  static const IconData search = Icons.search_rounded;
  static const IconData settingsGear = Icons.settings_outlined;
  static const IconData logout = Icons.logout_rounded;
  static const IconData edit = Icons.edit_outlined;
  static const IconData add = Icons.add_rounded;
  static const IconData check = Icons.check_rounded;

  // ── Navigation / modules ────────────────────────────────────
  static const IconData home = Icons.home_outlined;
  static const IconData medications = Icons.medication_outlined;
  static const IconData appointments = Icons.event_outlined;
  static const IconData scanner = Icons.qr_code_scanner_rounded;
  static const IconData aiFeatures = Icons.auto_awesome_outlined;
  static const IconData healthBot = Icons.smart_toy_outlined;
  static const IconData healthRecord = Icons.favorite_border_rounded;
  static const IconData findDoctors = Icons.search_outlined;
  static const IconData nearby = Icons.location_on_outlined;
  static const IconData reports = Icons.description_outlined;
  static const IconData settings = Icons.settings_outlined;

  // ── Scanner / media ─────────────────────────────────────────
  static const IconData camera = Icons.camera_alt_rounded;
  static const IconData gallery = Icons.photo_library_outlined;
  static const IconData document = Icons.upload_file_rounded;
  static const IconData cameraSwitch = Icons.cameraswitch_rounded;
  static const IconData delete = Icons.delete_outline_rounded;
  static const IconData science = Icons.science_outlined;

  // ── Clinical / AI ───────────────────────────────────────────
  static const IconData ai = Icons.auto_awesome_rounded;
  static const IconData report = Icons.description_outlined;
  static const IconData telemedicine = Icons.videocam_outlined;
  static const IconData inPerson = Icons.medical_services_outlined;
  static const IconData vitals = Icons.favorite_rounded;
  static const IconData calendar = Icons.calendar_today_outlined;
  static const IconData clock = Icons.schedule_rounded;
}
