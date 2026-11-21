import 'package:get/get.dart';

import '../../../data/services/progress_service.dart';
import '../../../routes/app_routes.dart';

class SplashController extends GetxController {
  final ProgressService _progress = Get.find();

  @override
  void onReady() {
    super.onReady();
    Future<void>.delayed(const Duration(milliseconds: 1700), () {
      Get.offAllNamed<void>(
        _progress.onboardingDone.value ? Routes.shell : Routes.onboarding,
      );
    });
  }
}
