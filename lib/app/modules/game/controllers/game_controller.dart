import 'dart:async';

import 'package:get/get.dart';

import '../../../config/app_config.dart';
import '../../../core/utils/day.dart';
import '../../../core/widgets/feedback.dart';
import '../../../data/game/board_logic.dart';
import '../../../data/game/level_catalog.dart';
import '../../../data/game/level_spec.dart';
import '../../../data/models/level_result.dart';
import '../../../data/services/ads_service.dart';
import '../../../data/services/audio_service.dart';
import '../../../data/services/progress_service.dart';
import '../../../data/services/settings_service.dart';
import '../../../data/services/wallet_service.dart';
import '../../../routes/app_routes.dart';
import '../models/board_arrow.dart';
import '../views/game_sheets.dart';

class GameController extends GetxController {
  final ProgressService progress = Get.find();
  final WalletService wallet = Get.find();
  final SettingsService settings = Get.find();
  final AudioService _audio = Get.find();
  final AdsService ads = Get.find();

  late final GameArgs args;
  late final LevelSpec spec;
  late final List<BoardArrow> arrows;
  late final Map<int, BoardArrow> _byId;

  final remaining = <int>{}.obs;
  final hearts = AppConfig.heartsPerLevel.obs;
  final aim = false.obs;
  final aimedId = RxnInt();
  final hintId = RxnInt();
  final flashIds = <int>{}.obs;
  final path = <Cell>[].obs;
  final pathTone = PathTone.none.obs;
  final pathVersion = 0.obs;
  final status = GameStatus.playing.obs;
  late final Rx<GameMessage> message;

  final _history = <int>[];
  final _watch = Stopwatch();
  int _taps = 0;
  int _crashes = 0;
  int _hintsUsed = 0;
  int _unflushedArrows = 0;
  Timer? _flashTimer;

  // ----- Setup ----------------------------------------------------------------

  @override
  void onInit() {
    super.onInit();
    final a = Get.arguments;
    args = a is GameArgs ? a : GameArgs.campaign(progress.nextLevel);
    spec = args.mode == GameMode.daily
        ? LevelCatalog.daily(args.date!)
        : LevelCatalog.level(args.level);
    arrows = spec.arrows.map(BoardArrow.new).toList();
    _byId = {for (final b in arrows) b.id: b};
    aim.value = settings.aimByDefault.value;
    message = GameMessage(_startMessage, MsgTone.info).obs;
    _reset(initial: true);
  }

  String get _startMessage => args.mode == GameMode.campaign && args.level == 1
      ? 'msg_first_level'.tr
      : 'msg_start'.tr;

  bool get isDaily => args.mode == GameMode.daily;
  int get total => arrows.length;
  int get cleared => total - remaining.length;

  String get title => isDaily
      ? 'daily_challenge'.tr
      : 'level_n'.trParams({'n': '${args.level}'});

  String get subtitle {
    if (isDaily) return Day.key(args.date!);
    final ch = LevelCatalog.chapterOf(args.level);
    return 'chapter_label'.trParams({
      'num': '${ch.number}',
      'title': ch.titleKey.tr,
    });
  }

  void _reset({bool initial = false}) {
    remaining
      ..clear()
      ..addAll(arrows.map((a) => a.id));
    _history.clear();
    hearts.value = AppConfig.heartsPerLevel;
    _taps = 0;
    _crashes = 0;
    _hintsUsed = 0;
    status.value = GameStatus.playing;
    _clearHighlights();
    for (final (i, a) in arrows.indexed) {
      a.gone.value = false;
      a.play(ArrowFxKind.enter, delayMs: (initial ? 120 : 0) + i * 16);
    }
    _watch
      ..reset()
      ..start();
    if (!initial) _say('msg_restart'.tr, MsgTone.info);
  }

  // ----- Rules ----------------------------------------------------------------

  List<ArrowSpec> get _remainingSpecs =>
      arrows.where((a) => remaining.contains(a.id)).map((a) => a.spec).toList();

  RayResult _ray(int id) =>
      BoardLogic.castAgainst(_byId[id]!.spec, spec.size, _remainingSpecs);

  void tapArrow(int id) {
    if (status.value != GameStatus.playing || !remaining.contains(id)) return;
    hintId.value = null;

    if (aim.value && aimedId.value != id) {
      final ray = _ray(id);
      aimedId.value = id;
      _showPath(ray.cells, ray.isClear ? PathTone.aim : PathTone.blocked);
      flashIds.assignAll([if (!ray.isClear) ray.blockerId!]);
      _say(
        ray.isClear ? 'msg_aim_clear'.tr : 'msg_aim_blocked'.tr,
        ray.isClear ? MsgTone.info : MsgTone.warn,
      );
      _audio.play(Sfx.tap);
      settings.tick();
      return;
    }

    _taps++;
    aimedId.value = null;
    final ray = _ray(id);
    if (ray.isClear) {
      _clear(id, ray);
    } else {
      _crash(id, ray);
    }
  }

  void _clear(int id, RayResult ray) {
    remaining.remove(id);
    _history.add(id);
    _unflushedArrows++;
    _byId[id]!.play(ArrowFxKind.exit, cells: ray.cells.length + 2);
    _clearHighlights();
    _audio.play(Sfx.whoosh);
    settings.lightImpact();
    if (remaining.isEmpty) {
      unawaited(_win());
    } else {
      _say('msg_nice'.trParams({'n': '${remaining.length}'}), MsgTone.good);
    }
  }

  void _crash(int id, RayResult ray) {
    hearts.value--;
    _crashes++;
    _byId[id]!.play(ArrowFxKind.bump, cells: ray.cells.length);
    _byId[ray.blockerId!]!.play(
      ArrowFxKind.shake,
      delayMs: 60 + ray.cells.length * 30,
    );
    _showPath(ray.cells, PathTone.blocked);
    flashIds.assignAll([id, ray.blockerId!]);
    _audio.play(Sfx.crash);
    settings.heavyImpact();
    _flashTimer?.cancel();
    _flashTimer = Timer(const Duration(milliseconds: 900), () {
      flashIds.clear();
      if (pathTone.value == PathTone.blocked) {
        _showPath(const [], PathTone.none);
      }
    });
    if (hearts.value <= 0) {
      status.value = GameStatus.lost;
      _say('msg_out_of_hearts'.tr, MsgTone.bad);
      unawaited(_flushArrows());
      Future<void>.delayed(const Duration(milliseconds: 650), () {
        if (status.value == GameStatus.lost && !isClosed) {
          unawaited(GameSheets.outOfHearts(this));
        }
      });
    } else {
      _say('msg_crash'.tr, MsgTone.bad);
    }
  }

  Future<void> _win() async {
    status.value = GameStatus.won;
    _watch.stop();
    _say('msg_cleared'.tr, MsgTone.good);
    await _flushArrows();
    final stars = LevelResult.starsFor(_crashes);
    var earnedHint = false;
    var firstClear = false;
    var streak = 0;
    if (isDaily) {
      streak = await progress.recordDailySolve(args.date!);
    } else {
      final outcome = await progress.recordLevelClear(
        level: args.level,
        starCount: stars,
        usedHint: _hintsUsed > 0,
      );
      earnedHint = outcome.earnedHint;
      firstClear = outcome.firstClear;
      if (earnedHint) wallet.addHints(1);
    }
    _audio.play(Sfx.win);
    settings.success();
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (isClosed) return;
    await Get.offNamed<void>(
      Routes.result,
      arguments: LevelResult(
        args: args,
        stars: stars,
        taps: _taps,
        crashes: _crashes,
        heartsLeft: hearts.value,
        hintsUsed: _hintsUsed,
        duration: _watch.elapsed,
        earnedHint: earnedHint,
        firstClear: firstClear,
        streak: streak,
      ),
    );
  }

  // ----- Tools ----------------------------------------------------------------

  void undo() {
    if (status.value != GameStatus.playing) return;
    if (_history.isEmpty) {
      _say('msg_nothing_undo'.tr, MsgTone.info);
      return;
    }
    final id = _history.removeLast();
    remaining.add(id);
    _unflushedArrows = (_unflushedArrows - 1).clamp(0, 1 << 30);
    final a = _byId[id]!;
    a.gone.value = false;
    a.play(ArrowFxKind.undo);
    _clearHighlights();
    _audio.play(Sfx.tap);
    _say('msg_undone'.tr, MsgTone.info);
  }

  void useHint() {
    if (status.value != GameStatus.playing) return;
    if (wallet.hints.value <= 0) {
      unawaited(GameSheets.outOfHints(this));
      return;
    }
    final free = BoardLogic.freeArrows(spec.size, _remainingSpecs);
    if (free.isEmpty) return;
    // Prefer the arrow that unblocks the most others.
    free.sort((a, b) => _blocks(b).compareTo(_blocks(a)));
    final pick = free.first;
    wallet.spendHint();
    _hintsUsed++;
    unawaited(progress.addHintUsed());
    aimedId.value = null;
    flashIds.clear();
    hintId.value = pick.id;
    _showPath(_ray(pick.id).cells, PathTone.hint);
    _audio.play(Sfx.hint);
    settings.tick();
    _say('msg_hint'.tr, MsgTone.warn);
  }

  int _blocks(ArrowSpec a) {
    var n = 0;
    final specs = _remainingSpecs;
    for (final other in specs) {
      if (other.id == a.id) continue;
      if (BoardLogic.castAgainst(other, spec.size, specs).blockerId == a.id) {
        n++;
      }
    }
    return n;
  }

  void toggleAim() {
    aim.toggle();
    aimedId.value = null;
    _clearHighlights();
    _audio.play(Sfx.tap);
    _say(aim.value ? 'msg_aim_on'.tr : 'msg_aim_off'.tr, MsgTone.info);
  }

  void restart() {
    _audio.play(Sfx.tap);
    unawaited(_flushArrows());
    _reset();
  }

  /// Out of hearts: continue with one heart after a rewarded ad.
  Future<void> reviveWithAd() async {
    final ok = await ads.showRewarded();
    if (ok) {
      _revive();
    } else {
      AppToast.show('ad_not_ready'.tr);
    }
  }

  /// Out of hearts: continue with one heart for one hint.
  bool reviveWithHint() {
    if (!wallet.spendHint()) return false;
    _hintsUsed++;
    _revive();
    return true;
  }

  void _revive() {
    hearts.value = 1;
    status.value = GameStatus.playing;
    _audio.play(Sfx.reward);
    _say('msg_revived'.tr, MsgTone.good);
  }

  Future<void> earnHintWithAd() async {
    final ok = await ads.showRewarded();
    if (ok) {
      wallet.addHints(1);
      _audio.play(Sfx.reward);
      AppToast.show('hint_earned_toast'.tr, tone: ToastTone.good);
    } else {
      AppToast.show('ad_not_ready'.tr);
    }
  }

  Future<void> pause() => GameSheets.pause(this);

  void exitToLevels() {
    Get.back<void>();
  }

  // ----- Helpers --------------------------------------------------------------

  void _showPath(List<Cell> cells, PathTone tone) {
    path.assignAll(cells);
    pathTone.value = tone;
    pathVersion.value++;
  }

  void _clearHighlights() {
    hintId.value = null;
    flashIds.clear();
    _showPath(const [], PathTone.none);
  }

  void _say(String text, MsgTone tone) =>
      message.value = GameMessage(text, tone);

  Future<void> _flushArrows() async {
    final n = _unflushedArrows;
    _unflushedArrows = 0;
    await progress.addArrows(n);
  }

  @override
  void onClose() {
    _flashTimer?.cancel();
    unawaited(_flushArrows());
    super.onClose();
  }
}
