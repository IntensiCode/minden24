import 'dart:async';

import 'package:dart_minilog/dart_minilog.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

import 'soundboard.dart';

class SoundboardImpl extends Soundboard {
  late final SoLoud soloud;

  final _one_shots = <String, Future<AudioSource>>{};
  (AudioSource, SoundHandle)? _active_music;

  final _sounds = <Sound, AudioSource>{};

  // final _max_sounds = <SoundHandle>[];
  final _last_time = <AudioSource, int>{};

  @override
  Future onLoad() async {
    super.onLoad();
    soloud = SoLoud.instance;
    await soloud.init();
  }

  @override
  double? get active_music_volume {
    final active = _active_music;
    if (active == null) return null;
    return soloud.getVolume(active.$2);
  }

  @override
  set active_music_volume(double? it) {
    final active = _active_music;
    if (active == null) return;
    if (it == null || it == 0) {
      soloud.setVolume(active.$2, 0);
      final paused = soloud.getPause(active.$2);
      if (!paused) soloud.pauseSwitch(active.$2);
    } else {
      soloud.setVolume(active.$2, it);
      final paused = soloud.getPause(active.$2);
      if (paused) soloud.pauseSwitch(active.$2);
    }
  }

  @override
  Future do_init_and_preload() async {
    if (_sounds.isEmpty) await _preload_sounds();
  }

  Future _preload_sounds() async {
    for (final it in Sound.values) {
      try {
        _sounds[it] = await soloud.loadAsset('assets/audio/sound/${it.name}.ogg');
      } catch (e) {
        logError('failed loading $it: $e');
      }
    }
  }

  @override
  void do_update_volume() {
    logInfo('update volume $music');
    active_music_volume = music;
  }

  @override
  Future do_play(Sound sound, double volume_factor) async {
    final it = _sounds[sound];
    if (it == null) {
      logError('null sound: $sound');
      preload();
      return;
    }

    final last_played_at = _last_time[it] ?? 0;
    final now = DateTime.timestamp().millisecondsSinceEpoch;
    if (now < last_played_at + 100) return;
    _last_time[it] = now;

    // _max_sounds.removeWhere((it) => it.state != PlayerState.playing);
    // if (_max_sounds.length > 10) {
    //   final fifo = _max_sounds.removeAt(0);
    //   await fifo.stop();
    // }

    // if (it.state != PlayerState.stopped) await it.stop();
    // await it.setVolume((volume_factor * super.sound).clamp(0, 1));
    // await it.resume();
    await soloud.play(it, volume: (volume_factor * super.sound).clamp(0, 1));
  }

  @override
  Future do_play_one_shot_sample(String filename, double volume_factor) async {
    final source = _one_shots.putIfAbsent(filename, () => soloud.loadAsset(filename));
    await soloud.play(await source, volume: (volume_factor * super.sound).clamp(0, 1));
  }

  @override
  Future do_play_music(String filename) async {
    do_stop_active_music();

    // because of the async-ness, double check no other music started by now:
    if (_active_music != null) return;

    final source = await soloud.loadAsset('assets/audio/$filename');
    _active_music = (source, await soloud.play(source, volume: music, looping: true));

    logInfo('playing music via soloud: $filename');
  }

  @override
  void do_stop_active_music() async {
    final active = _active_music;
    if (active == null) return;

    logInfo('stopping active music');

    _active_music = null;
    await soloud.stop(active.$2);
    await soloud.disposeSource(active.$1);
  }
}
