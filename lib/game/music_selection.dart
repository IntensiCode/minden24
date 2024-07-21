import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame/sprite.dart';

import '../components/basic_menu.dart';
import '../core/core.dart';
import '../util/auto_dispose.dart';
import '../util/extensions.dart';
import '../util/fonts.dart';
import '../util/functions.dart';
import '../util/game_keys.dart';
import '../util/on_message.dart';
import '../util/storage.dart';
import 'game_dialog.dart';
import 'game_messages.dart';
import 'soundboard.dart';

enum MusicTrack {
  city_of_minden,
  liberation_of_minden,
  shadows_of_minden,
  drifting_through_space,
}

class MusicSelection extends Component with AutoDispose {
  static final _dialog_size = Vector2(320, 200);

  late final SpriteSheet _menu_entry;

  MusicTrack? now_playing;

  Hook? _pending_on_end;

  @override
  Future onLoad() async {
    super.onLoad();

    await soundboard.preload();

    priority = 100;

    _menu_entry = await sheetI('button_menu.png', 1, 2);

    final selected = (await load_data('music_selection')) ?? {};
    _play(selected['music'] as String? ?? 'city_of_minden');

    onMessage<PickMusic>((it) => pick_music());
    onMessage<PlayEndMusic>((it) {
      now_playing = null;

      // ignore: prefer_function_declarations_over_variables
      final resume_game_music = () {
        it.when_done();
        _pending_on_end = null;
        _play((now_playing ?? MusicTrack.values.random()).name);
      };

      _pending_on_end = null;
      _pending_on_end = resume_game_music;

      final music_pick = 1 + Random(DateTime.timestamp().millisecondsSinceEpoch).nextInt(4);
      soundboard.fade_out_music();
      soundboard.play_music('music/end$music_pick.ogg', loop: false, on_end: () {
        if (_pending_on_end == resume_game_music) _pending_on_end?.call();
      });
    });
  }

  void _play(String which) {
    if (now_playing?.name == which) return;

    now_playing = MusicTrack.values.firstWhere((it) => it.name == which);
    soundboard.fade_out_music();
    soundboard.play_music('music/$which.ogg');
    save_data('music_selection', {'music': which});
  }

  void pick_music() {
    if (children.whereType<GameDialog>().isNotEmpty) return;

    GameDialog? dialog;
    add(dialog = GameDialog(
      size: _dialog_size,
      content: _create_menu(() => dialog?.fadeOutDeep()),
      keys: DialogKeys(
        handlers: {
          GameKey.soft1: () => dialog?.fadeOutDeep(),
          GameKey.soft2: () => dialog?.fadeOutDeep(),
        },
        right: 'Ok',
      ),
    )..fadeInDeep());
  }

  PositionComponent _create_menu(Hook and_then) => BasicMenu<MusicTrack>(
        button: _menu_entry,
        font: menu_font,
        fontScale: 0.5,
        fixed_position: _dialog_size / 2,
        fixed_anchor: Anchor.center,
        onSelected: (it) {
          _play(it.name);
          and_then();
        },
      )
        ..addEntry(MusicTrack.city_of_minden, 'City of Minden')
        ..addEntry(MusicTrack.liberation_of_minden, 'Liberation of Minden')
        ..addEntry(MusicTrack.shadows_of_minden, 'Shadows of Minden')
        ..addEntry(MusicTrack.drifting_through_space, 'Drifting Through Space')
        ..preselectEntry(now_playing);
}
