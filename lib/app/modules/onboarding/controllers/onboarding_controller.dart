import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../data/models/level_result.dart';
import '../../../data/services/progress_service.dart';
import '../../../routes/app_routes.dart';

class OnboardingController extends GetxController {
  final ProgressService _progress = Get.find();
  final pageController = PageController();
  final page = 0.obs;

  static const pageCount = 3;

  bool get isLast => page.value == pageCount - 1;

  void onPageChanged(int i) => page.value = i;

  void next() {
    if (isLast) {
      _finish(play: true);
      return;
    }
    pageController.nextPage(
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }

  void skip() => _finish(play: false);

  Future<void> _finish({required bool play}) async {
    await _progress.completeOnboarding();
    await Get.offAllNamed<void>(Routes.shell);
    if (play) {
      await Get.toNamed<void>(
        Routes.game,
        arguments: const GameArgs.campaign(1),
      );
    }
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}
