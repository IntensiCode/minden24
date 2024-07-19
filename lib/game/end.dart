import 'package:flame/components.dart';
import 'package:minden24/util/extensions.dart';

import '../core/core.dart';
import '../util/game_script.dart';
import '../util/keys.dart';
import 'game_dialog.dart';

class End extends GameScriptComponent {
  static final _dialog_size = game_size;

  @override
  void onLoad() async {
    await add(GameDialog(
      size: _dialog_size,
      content: await spriteXY('end.png', 0, 0, Anchor.topLeft),
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
