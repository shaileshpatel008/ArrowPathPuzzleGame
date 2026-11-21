import 'package:get/get.dart';

enum ShellTab { home, levels, daily, settings }

class ShellController extends GetxController {
  final tab = ShellTab.home.obs;

  void select(ShellTab t) => tab.value = t;

  /// Android back: return to Home first, exit from Home.
  bool handleBack() {
    if (tab.value == ShellTab.home) return true;
    tab.value = ShellTab.home;
    return false;
  }
}
