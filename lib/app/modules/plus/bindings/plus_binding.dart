import 'package:get/get.dart';

import '../controllers/plus_controller.dart';

class PlusBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut(PlusController.new);
}
