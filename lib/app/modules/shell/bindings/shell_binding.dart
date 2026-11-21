import 'package:get/get.dart';

import '../../daily/controllers/daily_controller.dart';
import '../../home/controllers/home_controller.dart';
import '../../levels/controllers/levels_controller.dart';
import '../../settings/controllers/settings_controller.dart';
import '../controllers/shell_controller.dart';

class ShellBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(ShellController.new, fenix: true);
    Get.lazyPut(HomeController.new, fenix: true);
    Get.lazyPut(LevelsController.new, fenix: true);
    Get.lazyPut(DailyController.new, fenix: true);
    Get.lazyPut(SettingsController.new, fenix: true);
  }
}
