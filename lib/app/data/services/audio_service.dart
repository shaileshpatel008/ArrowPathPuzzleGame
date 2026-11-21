import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import 'settings_service.dart';

enum Sfx {
  tap('tap.wav', 0.55),
  whoosh('whoosh.wav', 0.6),
  crash('crash.wav', 0.8),
  hint('hint.wav', 0.7),
  star('star.wav', 0.6),
  win('win.wav', 0.75),
  reward('reward.wav', 0.7);

  const Sfx(this.file, this.volume);
  final String file;
  final double volume;
}

/// Sound effects + optional background music.
///
/// Audio mixes with other apps (it never stops the player's own music) and
/// pauses when the app goes to the background.
class AudioService extends GetxService with WidgetsBindingObserver {
  AudioService(this._settings);

  final SettingsService _settings;
  final _pools = <Sfx, AudioPool>{};
  AudioPlayer? _music;
  bool _inForeground = true;

  Future<AudioService> init() async {
    try {
      AudioCache.instance = AudioCache(prefix: 'assets/audio/');
      await AudioPlayer.global.setAudioContext(
        AudioContextConfig(focus: AudioContextConfigFocus.mixWithOthers)
            .build(),
      );
      for (final s in Sfx.values) {
        _pools[s] = await AudioPool.create(
          source: AssetSource(s.file),
          maxPlayers: s == Sfx.tap || s == Sfx.whoosh ? 4 : 2,
          playerMode: PlayerMode.lowLatency,
        );
      }
      _music = AudioPlayer(playerId: 'music');
      await _music!.setReleaseMode(ReleaseMode.loop);
      await _music!.setVolume(0.32);
    } catch (e) {
      debugPrint('AudioService init failed: $e');
    }
    WidgetsBinding.instance.addObserver(this);
    ever<bool>(_settings.music, (_) => _syncMusic());
    unawaited(_syncMusic());
    return this;
  }

  void play(Sfx sfx) {
    if (!_settings.sound.value) return;
    final pool = _pools[sfx];
    if (pool == null) return;
    unawaited(_start(pool, sfx.volume));
  }

  Future<void> _start(AudioPool pool, double volume) async {
    try {
      await pool.start(volume: volume);
    } catch (e) {
      debugPrint('sfx: $e');
    }
  }

  Future<void> _syncMusic() async {
    final player = _music;
    if (player == null) return;
    try {
      if (_settings.music.value && _inForeground) {
        if (player.state != PlayerState.playing) {
          await player.play(AssetSource('music_loop.wav'));
        }
      } else if (player.state == PlayerState.playing) {
        await player.pause();
      }
    } catch (e) {
      debugPrint('music: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _inForeground = state == AppLifecycleState.resumed;
    unawaited(_syncMusic());
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    for (final p in _pools.values) {
      unawaited(p.dispose());
    }
    unawaited(_music?.dispose());
    super.onClose();
  }
}
