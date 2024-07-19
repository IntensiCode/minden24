import 'package:flame/components.dart';

import '../components/flow_text.dart';
import '../core/core.dart';
import '../util/bitmap_text.dart';
import '../util/fonts.dart';
import '../util/game_script.dart';
import '../util/keys.dart';
import 'game_dialog.dart';

class Credits extends GameScriptComponent {
  static final _dialog_size = Vector2(640, 400);

  @override
  void onLoad() async {
    var text = await game.assets.readFile('data/credits.txt');
    text = text.split('\n').join('').replaceAll('---', '\n\n');

    final content = PositionComponent(
      size: Vector2(640, 480),
      children: [
        BitmapText(
          text: 'Credits',
          font: menu_font,
          position: Vector2(_dialog_size.x / 2, 32),
          anchor: Anchor.center,
        ),
        FlowText(
          text: text,
          font: menu_font,
          font_scale: 0.5,
          position: Vector2(_dialog_size.x / 2, _dialog_size.y - 16),
          size: Vector2(640 - 23, 400 - 96),
          anchor: Anchor.bottomCenter,
        ),
      ],
    );

    await add(GameDialog(
      size: _dialog_size,
      content: content,
      keys: DialogKeys(
        handlers: {
          GameKey.soft1: () => removeFromParent(),
          GameKey.soft2: () => removeFromParent(),
        },
        left: 'Ok',
        tap_key: GameKey.soft2,
      ),
    ));
  }
}
