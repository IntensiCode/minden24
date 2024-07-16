import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/sprite.dart';

import '../components/basic_menu.dart';
import '../components/basic_menu_button.dart';
import '../components/flow_text.dart';
import '../core/core.dart';
import '../util/bitmap_text.dart';
import '../util/fonts.dart';
import '../util/functions.dart';
import '../util/game_keys.dart';
import 'game_dialog.dart';
import 'minden_game.dart';
import 'minden_settings.dart';

enum _Choice {
  easy,
  normal,
  hard,
  very_hard,
  toggle_shuffle,
}

class NewGameDialog extends Component {
  static final _dialog_size = Vector2(640, 400);

  late final SpriteSheet _menu_entry;
  late final String _help_text;

  late BasicMenuButton _toggle_shuffle;

  @override
  Future onLoad() async {
    super.onLoad();
    priority = 100;
    _menu_entry = await sheetI('button_menu.png', 1, 2);
    _help_text = await game.assets.readFile('data/help_difficulty.txt');
  }

  void try_again() {
    _pick_difficulty(and_then: (it) {
      minden_game.new_game(new_game_settings: it);
      minden_game.save();
    });
  }

  void new_game() {
    _pick_difficulty(and_then: (it) {
      final start_settings = it.copy(game_seed: Random().nextInt(4294967296));
      minden_game.new_game(new_game_settings: start_settings);
      minden_game.save();
    });
  }

  void _pick_difficulty({required void Function(MindenSettings) and_then}) {
    if (children.whereType<GameDialog>().isNotEmpty) return;

    GameDialog? dialog;
    add(dialog = GameDialog(
      size: _dialog_size,
      content: _create_menu((it) {
        and_then(it);
        dialog?.removeFromParent();
      }),
      keys: DialogKeys(
        handlers: {GameKey.soft1: () => dialog?.removeFromParent()},
        left: 'Cancel',
      ),
    ));
  }

  PositionComponent _create_menu(void Function(MindenSettings) and_then) {
    var new_settings = minden_game.settings.copy();
    final menu = BasicMenu<_Choice>(
      button: _menu_entry,
      font: menu_font,
      fontScale: 0.5,
      fixed_position: Vector2(_dialog_size.x / 2, 160),
      fixed_anchor: Anchor.center,
      onSelected: (it) {
        switch (it) {
          case _Choice.easy:
            and_then(new_settings.copy(difficulty: Difficulty.easy));
          case _Choice.normal:
            and_then(new_settings.copy(difficulty: Difficulty.normal));
          case _Choice.hard:
            and_then(new_settings.copy(difficulty: Difficulty.hard));
          case _Choice.very_hard:
            and_then(new_settings.copy(difficulty: Difficulty.very_hard));
          case _Choice.toggle_shuffle:
            new_settings = new_settings.copy(easy_shuffle: !new_settings.easy_shuffle);
            _toggle_shuffle.checked = new_settings.easy_shuffle;
        }
      },
    )
      ..addEntry(_Choice.easy, 'Easy')
      ..addEntry(_Choice.normal, 'Normal')
      ..addEntry(_Choice.hard, 'Hard')
      ..addEntry(_Choice.very_hard, 'Very Hard')
      ..preselectEntry(switch (new_settings.difficulty) {
        Difficulty.easy => _Choice.easy,
        Difficulty.normal => _Choice.normal,
        Difficulty.hard => _Choice.hard,
        Difficulty.very_hard => _Choice.very_hard,
      });

    _toggle_shuffle = menu.addEntry(_Choice.toggle_shuffle, 'Easy Shuffle', anchor: Anchor.centerLeft);
    _toggle_shuffle.checked = new_settings.easy_shuffle;

    final content = PositionComponent(size: _dialog_size);
    content.add(BitmapText(
      text: 'Choose Difficulty',
      font: menu_font,
      position: Vector2(_dialog_size.x / 2, 32),
      anchor: Anchor.center,
    ));
    content.add(menu);
    content.add(FlowText(
      text: _help_text,
      font: menu_font,
      font_scale: 0.4,
      position: Vector2(_dialog_size.x / 2, _dialog_size.y - 16),
      size: Vector2(_dialog_size.x - 32, 112),
      anchor: Anchor.bottomCenter,
    ));

    return content;
  }
}
