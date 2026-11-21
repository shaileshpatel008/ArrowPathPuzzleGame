import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../core/constants/storage_keys.dart';
import '../../core/theme/skins.dart';
import 'storage_service.dart';

/// Player preferences. Every field is reactive and persisted on change.
class SettingsService extends GetxService {
  SettingsService(this._storage);

  final StorageService _storage;

  late final RxString skinId;
  late final RxBool aimByDefault;
  late final RxBool sound;
  late final RxBool music;
  late final RxBool haptics;
  late final RxBool colorBlind;
  late final RxBool reduceMotion;

  SettingsService init() {
    skinId = (_storage.readString(StorageKeys.skinId) ?? Skins.daylight.id).obs;
    aimByDefault = _bool(StorageKeys.aimByDefault, false);
    sound = _bool(StorageKeys.sound, true);
    music = _bool(StorageKeys.music, false);
    haptics = _bool(StorageKeys.haptics, true);
    colorBlind = _bool(StorageKeys.colorBlind, false);
    reduceMotion = _bool(StorageKeys.reduceMotion, false);
    ever<String>(skinId, (v) => _storage.write(StorageKeys.skinId, v));
    return this;
  }

  Skin get skin => Skins.byId(skinId.value);

  RxBool _bool(String key, bool fallback) {
    final rx = _storage.readBool(key, fallback: fallback).obs;
    ever<bool>(rx, (v) => _storage.write(key, v));
    return rx;
  }

  // ----- Haptics --------------------------------------------------------------

  void tick() {
    if (haptics.value) HapticFeedback.selectionClick();
  }

  void lightImpact() {
    if (haptics.value) HapticFeedback.lightImpact();
  }

  void heavyImpact() {
    if (haptics.value) HapticFeedback.heavyImpact();
  }

  void success() {
    if (haptics.value) HapticFeedback.mediumImpact();
  }
}
