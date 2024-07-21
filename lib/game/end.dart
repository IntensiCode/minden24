import 'dart:math';

import 'package:flame/components.dart';

import '../core/core.dart';
import '../util/extensions.dart';
import '../util/game_script.dart';
import '../util/keys.dart';
import 'game_dialog.dart';
import 'soundboard.dart';

class End extends GameScriptComponent {
  static final _dialog_size = game_size;

  @override
  void onLoad() async {
    final music_pick = 1 + Random(DateTime.timestamp().millisecondsSinceEpoch).nextInt(4);

    soundboard.fade_out_music();
    soundboard.play_music('music/end$music_pick.ogg');

    final pick = 1 + Random(DateTime.timestamp().millisecondsSinceEpoch).nextInt(3);
    await add(GameDialog(
      size: _dialog_size,
      content: await spriteXY('end$pick.png', 0, 0, Anchor.topLeft),
      background: false,
      keys: DialogKeys(
        handlers: {
          GameKey.soft1: () => fadeOutDeep(),
          GameKey.soft2: () => fadeOutDeep(),
        },
        tap_key: GameKey.soft2,
      ),
    ));
  }
}
