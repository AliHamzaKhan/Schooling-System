import 'package:get/get.dart';

import '../controller/report_card_controller.dart';

class ReportCardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ReportCardController>(() => ReportCardController());
  }
}
