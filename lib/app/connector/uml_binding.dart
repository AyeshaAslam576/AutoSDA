import 'package:get/get.dart';

import '../features/uml/controllers/uml_controller.dart';

class UmlBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<UmlController>(() => UmlController());
  }
}
