import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/sprite.dart';

import '../components/basic_menu.dart';
import '../components/basic_menu_button.dart';
import '../components/flow_text.dart';
import '../core/core.dart';
import '../util/auto_dispose.dart';
import '../util/bitmap_text.dart';
import '../util/fonts.dart';
import '../util/functions.dart';
import '../util/game_keys.dart';
import '../util/messaging.dart';
import '../util/on_message.dart';
import 'game_dialog.dart';
import 'minden_game.dart';
import 'minden_settings.dart';

class _Refresh with Message {}

class NewGameDialog extends Component {
  static final _dialog_size = Vector2(640, 400);

  late final SpriteSheet _menu_entry;
  late final String _help_text;

  late MindenSettings _new_settings;

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

    _new_settings = minden_game.settings.copy();

    GameDialog? dialog;
    add(dialog = GameDialog(
      size: _dialog_size,
      content: _create_menu(),
      keys: DialogKeys(
        handlers: {
          GameKey.soft1: () {
            dialog?.removeFromParent();
          },
          GameKey.soft2: () {
            and_then(_new_settings);
            dialog?.removeFromParent();
          },
        },
        left: 'Cancel',
        right: 'Start',
      ),
    ));
  }

  PositionComponent _create_menu() {
    late final BasicMenu menu;

    menu = BasicMenu<Difficulty>(
      button: _menu_entry,
      font: menu_font,
      fontScale: 0.5,
      fixed_position: Vector2(_dialog_size.x / 4, 160),
      fixed_anchor: Anchor.center,
      onSelected: (it) {
        switch (it) {
          case Difficulty.easy:
            _new_settings = _new_settings.copy(difficulty: Difficulty.easy);
          case Difficulty.normal:
            _new_settings = _new_settings.copy(difficulty: Difficulty.normal);
          case Difficulty.hard:
            _new_settings = _new_settings.copy(difficulty: Difficulty.hard);
          case Difficulty.very_hard:
            _new_settings = _new_settings.copy(difficulty: Difficulty.very_hard);
        }
        menu.preselectEntry(it);
      },
    )
      ..addEntry(Difficulty.easy, 'Original 2x8 [7]')
      ..addEntry(Difficulty.normal, '2x7 [6] Stack')
      ..addEntry(Difficulty.hard, '2x6 [5] Stack')
      ..addEntry(Difficulty.very_hard, '2x5 [4] Stack')
      ..preselectEntry(_new_settings.difficulty);

    final content = PositionComponent(size: _dialog_size);
    content.add(BitmapText(
      text: 'Choose Difficulty',
      font: menu_font,
      position: Vector2(_dialog_size.x / 2, 32),
      anchor: Anchor.center,
    ));
    content.add(BitmapText(
      text: 'Shuffle Stack Width',
      font: menu_font,
      scale: 0.5,
      position: Vector2(_dialog_size.x / 4, 72),
      anchor: Anchor.center,
    ));
    content.add(BitmapText(
      text: 'Options',
      font: menu_font,
      scale: 0.5,
      position: Vector2(_dialog_size.x * 2 / 3 + 30, 72),
      anchor: Anchor.center,
    ));

    content.add(menu);

    content.add(_Switch(
      sheet: _menu_entry,
      text: 'Easy Shuffle',
      y_pos: 92,
      checked: () => _new_settings.easy_shuffle,
      on_toggle: () => _new_settings = _new_settings.copy(easy_shuffle: !_new_settings.easy_shuffle),
    ));
    content.add(_Switch(
      sheet: _menu_entry,
      text: 'Auto Finish',
      y_pos: 126,
      checked: () => _new_settings.auto_finish,
      on_toggle: () => _new_settings = _new_settings.copy(auto_finish: !_new_settings.auto_finish),
    ));
    content.add(_Switch(
      sheet: _menu_entry,
      text: 'Allow Batch Drag',
      y_pos: 160,
      checked: () => _new_settings.batch_drag,
      on_toggle: () => _new_settings = _new_settings.copy(batch_drag: !_new_settings.batch_drag),
    ));
    content.add(_Switch(
      sheet: _menu_entry,
      text: 'Allow Tap To Place',
      y_pos: 194,
      checked: () => _new_settings.tap_to_auto_place,
      on_toggle: () => _new_settings = _new_settings.copy(tap_to_auto_place: !_new_settings.tap_to_auto_place),
    ));

    content.add(BasicMenuButton(
      'Original Settings',
      sheet: _menu_entry,
      font: menu_font,
      font_scale: 0.5,
      on_tap: () {
        _new_settings = _new_settings.copy(
          difficulty: Difficulty.easy,
          easy_shuffle: false,
          auto_finish: false,
          batch_drag: false,
          tap_to_auto_place: false,
        );
        sendMessage(_Refresh());
      },
    )..position.setValues(_dialog_size.x / 4 + 10, 240));

    content.add(FlowText(
      text: _help_text,
      font: menu_font,
      font_scale: 0.4,
      position: Vector2(_dialog_size.x / 2, _dialog_size.y - 8),
      size: Vector2(_dialog_size.x - 32, 112),
      anchor: Anchor.bottomCenter,
    ));

    return content;
  }
}

class _Switch extends BasicMenuButton with AutoDispose {
  _Switch({
    required SpriteSheet sheet,
    required String text,
    required double y_pos,
    required Check checked,
    required Hook on_toggle,
  })  : checked_state = checked,
        super(
          text,
          sheet: sheet,
          font: menu_font,
          font_scale: 0.5,
          text_anchor: Anchor.centerLeft,
          on_tap: () {},
        ) {
    this.checked = checked_state();
    this.position.x = 320;
    this.position.y = y_pos;
    super.on_tap = () {
      on_toggle();
      super.checked = checked_state();
    };
  }

  final Check checked_state;

  @override
  void onMount() {
    super.onMount();
    onMessage<_Refresh>((_) => this.checked = checked_state());
  }
}
