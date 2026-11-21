import 'package:get/get.dart';

import '../controllers/splash_controller.dart';

class SplashBinding extends Bindings {
  // Eager on purpose: SplashView never reads `controller`, so a lazyPut
  // would never create it and the app would wait on the splash forever.
  @override
  void dependencies() {
    Get.put(SplashController());
  }
}
