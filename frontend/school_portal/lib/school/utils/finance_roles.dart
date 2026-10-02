import 'package:get/get.dart';
import 'package:shared/shared.dart';

/// Whether the signed-in user is the Headmaster. A Headmaster's refunds,
/// credits, waivers and payroll corrections apply at once; finance staff
/// (Accountant) send them to the Headmaster for approval.
bool signedInAsHeadmaster() {
  if (!Get.isRegistered<AuthService>()) return false;
  return Get.find<AuthService>().roleCodes.contains('headmaster');
}
