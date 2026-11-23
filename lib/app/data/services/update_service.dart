import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:in_app_update/in_app_update.dart';

import '../../config/app_config.dart';
import '../../core/constants/storage_keys.dart';
import '../../modules/update/update_sheets.dart';
import 'storage_service.dart';

/// Google Play In-App Updates.
///
/// * Normal update: a friendly sheet offers "Update now". Play downloads it
///   in the background (flexible update) while the player keeps playing,
///   then we offer "Restart" to install it. "Later" snoozes the offer for
///   [AppConfig.updatePromptCooldown].
/// * Old version: when the installed version has been out of date for
///   [AppConfig.forceUpdateAfterDays] days, or the release has update
///   priority 4-5, Play's full-screen (immediate) update is shown.
/// * Prompts only appear on the main tabs, never in the middle of a level.
///
/// Only works for apps installed from Google Play (internal testing counts).
/// In `flutter run` builds the check fails quietly with an `[Update]` log.
class UpdateService extends GetxService with WidgetsBindingObserver {
  UpdateService(this._storage);

  final StorageService _storage;

  StreamSubscription<InstallStatus>? _installSub;
  bool _checking = false;
  bool _downloadReady = false;
  bool _sheetOpen = false;
  DateTime? _lastCheck;

  bool get _supported => !kIsWeb && Platform.isAndroid;

  @override
  void onInit() {
    super.onInit();
    if (!_supported) return;
    WidgetsBinding.instance.addObserver(this);
    try {
      _installSub = InAppUpdate.installUpdateListener.listen(
        _onInstallStatus,
        onError: (Object e) => _log('install listener error: $e'),
      );
    } catch (e) {
      _log('install listener unavailable: $e');
    }
  }

  /// Called whenever the main tabs become visible.
  Future<void> onHomeVisible() async {
    if (!_supported) return;
    if (_downloadReady) {
      unawaited(_offerRestart());
      return;
    }
    // At most one Play check every 30 minutes.
    final last = _lastCheck;
    if (last != null &&
        DateTime.now().difference(last) < const Duration(minutes: 30)) {
      return;
    }
    await _check();
  }

  Future<void> _check() async {
    if (_checking) return;
    _checking = true;
    _lastCheck = DateTime.now();
    try {
      final info = await InAppUpdate.checkForUpdate();
      _log(
        'availability=${info.updateAvailability.name} '
        'available=${info.availableVersionCode} '
        'staleDays=${info.clientVersionStalenessDays} '
        'priority=${info.updatePriority} '
        'status=${info.installStatus.name}',
      );

      if (info.installStatus == InstallStatus.downloaded) {
        _downloadReady = true;
        unawaited(_offerRestart());
        return;
      }

      switch (info.updateAvailability) {
        case UpdateAvailability.developerTriggeredUpdateInProgress:
          // An immediate update was interrupted: resume it.
          await InAppUpdate.performImmediateUpdate();
        case UpdateAvailability.updateAvailable:
          final stale = info.clientVersionStalenessDays ?? 0;
          final critical =
              info.updatePriority >= 4 ||
              stale >= AppConfig.forceUpdateAfterDays;
          if (critical && info.immediateUpdateAllowed) {
            _log('starting immediate update');
            await InAppUpdate.performImmediateUpdate();
          } else if (info.flexibleUpdateAllowed && _cooldownPassed()) {
            unawaited(_offerUpdate());
          }
        case UpdateAvailability.updateNotAvailable:
        case UpdateAvailability.unknown:
          break;
      }
    } catch (e) {
      // Not installed from Play (e.g. flutter run), offline, etc.
      _log('check skipped: $e');
    } finally {
      _checking = false;
    }
  }

  bool _cooldownPassed() {
    final last = _storage.readInt(StorageKeys.updatePromptAt);
    if (last == 0) return true;
    final since = DateTime.now().difference(
      DateTime.fromMillisecondsSinceEpoch(last),
    );
    return since >= AppConfig.updatePromptCooldown;
  }

  Future<void> _offerUpdate() async {
    if (_sheetOpen) return;
    _sheetOpen = true;
    final accepted = await UpdateSheets.updateAvailable() ?? false;
    _sheetOpen = false;
    if (!accepted) {
      await _storage.write(
        StorageKeys.updatePromptAt,
        DateTime.now().millisecondsSinceEpoch,
      );
      return;
    }
    try {
      final result = await InAppUpdate.startFlexibleUpdate();
      _log('flexible update: ${result.name}');
      if (result == AppUpdateResult.success) {
        UpdateSheets.downloadingToast();
      } else {
        await _storage.write(
          StorageKeys.updatePromptAt,
          DateTime.now().millisecondsSinceEpoch,
        );
      }
    } catch (e) {
      _log('flexible update failed: $e');
    }
  }

  void _onInstallStatus(InstallStatus status) {
    _log('install status: ${status.name}');
    if (status == InstallStatus.downloaded) {
      _downloadReady = true;
      unawaited(_offerRestart());
    }
  }

  Future<void> _offerRestart() async {
    if (_sheetOpen || !UpdateSheets.canShowNow) return;
    _sheetOpen = true;
    final restart = await UpdateSheets.updateReady() ?? false;
    _sheetOpen = false;
    if (!restart) return;
    try {
      await InAppUpdate.completeFlexibleUpdate();
    } catch (e) {
      _log('install failed: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && UpdateSheets.canShowNow) {
      unawaited(onHomeVisible());
    }
  }

  void _log(String message) => debugPrint('[Update] $message');

  @override
  void onClose() {
    _installSub?.cancel();
    if (_supported) WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }
}
