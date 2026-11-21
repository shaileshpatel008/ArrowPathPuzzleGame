import 'package:get/get.dart';

import '../../../core/theme/skins.dart';
import '../../../core/widgets/feedback.dart';
import '../../../data/game/level_catalog.dart';
import '../../../data/game/level_spec.dart';
import '../../../data/services/audio_service.dart';
import '../../../data/services/progress_service.dart';
import '../../../data/services/settings_service.dart';
import '../../../data/services/wallet_service.dart';
import '../../../routes/app_routes.dart';

class ThemesController extends GetxController {
  final SettingsService settings = Get.find();
  final WalletService wallet = Get.find();
  final ProgressService _progress = Get.find();
  final AudioService _audio = Get.find();

  /// A small puzzle used for the live preview.
  final LevelSpec preview = LevelCatalog.level(6);

  List<Skin> get skins => Skins.all;

  bool isUnlocked(Skin s) => switch (s.unlock) {
    SkinUnlock.free => true,
    SkinUnlock.level50 =>
      wallet.ownsAllThemes || _progress.highestCleared.value >= 50,
    SkinUnlock.streak14 =>
      wallet.ownsAllThemes || _progress.streakState.value.best >= 14,
  };

  bool get showUnlockBanner => !wallet.ownsAllThemes;

  void select(Skin s) {
    if (!isUnlocked(s)) {
      AppToast.show('theme_locked_toast'.trParams({'rule': s.noteKey.tr}));
      return;
    }
    if (settings.skinId.value == s.id) return;
    settings.skinId.value = s.id;
    _audio.play(Sfx.reward);
    settings.success();
  }

  void openStore() => Get.toNamed<void>(Routes.store);
}
