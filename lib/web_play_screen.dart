import 'package:flame/components.dart';

import '../../util/auto_dispose.dart';
import '../util/bitmap_button.dart';
import '../util/fonts.dart';
import 'core/core.dart';
import 'core/screens.dart';
import 'util/shortcuts.dart';

class WebPlayScreen extends AutoDisposeComponent with HasAutoDisposeShortcuts {
  @override
  void onMount() => onKey('<Space>', () => _leave());

  @override
  onLoad() async {
    final button = await images.load('button_plain.png');
    const scale = 0.5;
    add(BitmapButton(
      bg_nine_patch: button,
      text: 'Start',
      font: menu_font,
      font_scale: scale,
      position: Vector2(game_width / 2, game_height / 2),
      anchor: Anchor.center,
      onTap: (_) => _leave(),
    ));
  }

  void _leave() {
    showScreen(Screen.game, skip_fade_out: true, skip_fade_in: true);
    removeFromParent();
  }
}
