import 'dart:math';

import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';

import '../core/core.dart';
import '../util/extensions.dart';
import '../util/game_script.dart';
import '../util/keys.dart';
import '../util/messaging.dart';
import 'game_dialog.dart';
import 'game_messages.dart';

class End extends GameScriptComponent {
  static final _dialog_size = game_size;

  @override
  void onLoad() async {
    sendMessage(PlayEndMusic(() {
      logInfo('end music done');
      if (isMounted && !isRemoving && !isRemoved) {
        removeFromParent();
      }
    }));

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
