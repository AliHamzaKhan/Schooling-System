import 'package:get/get.dart';

import '../controller/matrix_controller.dart';

class MatrixBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MatrixController>(() => MatrixController());
  }
}
