import 'package:get/get.dart';

import '../../../data/guardian_repository.dart';
import '../../../shared/controller/child_scoped_controller.dart';
import '../models/meeting_data.dart';

class MeetingController extends ChildScopedController<MeetingData> {
  final GuardianRepository _repo;
  MeetingController({GuardianRepository? repo})
      : _repo = repo ?? Get.find<GuardianRepository>();

  @override
  Future<MeetingData?> fetch(String childId) async {
    final res = await _repo.loadMeetings(childId);
    return res.success ? res.data : null;
  }
}
