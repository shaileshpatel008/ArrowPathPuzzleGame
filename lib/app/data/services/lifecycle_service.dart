import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import 'progress_service.dart';
import 'wallet_service.dart';

/// Re-checks daily perks whenever the app comes back to the foreground
/// (players often leave the game open overnight).
class LifecycleService extends GetxService with WidgetsBindingObserver {
  LifecycleService(this._wallet, this._progress);

  final WalletService _wallet;
  final ProgressService _progress;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _refreshDaily();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshDaily();
  }

  void _refreshDaily() {
    unawaited(_wallet.grantDailyPlusHints());
    unawaited(_progress.grantWeeklyFreeze(isPlus: _wallet.isPlus.value));
    _progress.streakState.refresh();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }
}
