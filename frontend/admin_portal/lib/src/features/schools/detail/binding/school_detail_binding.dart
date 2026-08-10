import 'package:get/get.dart';

import '../../models/school.dart';
import '../controller/school_detail_controller.dart';

class SchoolDetailBinding extends Bindings {
  @override
  void dependencies() {
    final school = Get.arguments as School;
    Get.lazyPut<SchoolDetailController>(
        () => SchoolDetailController(school: school));
  }
}
