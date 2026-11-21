import 'dart:async';

import 'package:get/get.dart';

import '../../../data/services/progress_service.dart';
import '../../../routes/app_routes.dart';

class SplashController extends GetxController {
  final ProgressService _progress = Get.find();
  Timer? _timer;

  static const showFor = Duration(milliseconds: 1700);

  @override
  void onInit() {
    super.onInit();
    // Started in onInit (not onReady) so navigation never depends on a
    // later frame callback.
    _timer = Timer(showFor, _goNext);
  }

  void _goNext() {
    Get.offAllNamed<void>(
      _progress.onboardingDone.value ? Routes.shell : Routes.onboarding,
    );
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}
