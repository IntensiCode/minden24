import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:minden24/util/extensions.dart';

import '../components/basic_menu.dart';
import '../core/core.dart';
import '../util/auto_dispose.dart';
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

  late MusicTrack now_playing;

  @override
  Future onLoad() async {
    super.onLoad();

    await soundboard.preload();

    priority = 100;

    _menu_entry = await sheetI('button_menu.png', 1, 2);

    final selected = (await load_data('music_selection')) ?? {};
    final which = selected['music'] as String? ?? 'city_of_minden';
    _play(which);

    onMessage<PickMusic>((it) => pick_music());
  }

  void _play(String which) {
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
