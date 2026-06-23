import 'package:get/get.dart';

import '../../../data/guardian_repository.dart';
import '../../../shared/controller/child_scoped_controller.dart';
import '../models/report_card_data.dart';

/// Loads the active child's report card; reloads automatically on child switch
/// via [ChildScopedController].
class ReportCardController extends ChildScopedController<ReportCardData> {
  final GuardianRepository _repo;
  ReportCardController({GuardianRepository? repo})
      : _repo = repo ?? Get.find<GuardianRepository>();

  @override
  Future<ReportCardData?> fetch(String childId) async {
    final res = await _repo.loadReportCard(childId);
    return res.success ? res.data : null;
  }
}
