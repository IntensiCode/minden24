import 'dart:ui';

import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';

import '../components/volume_component.dart';
import '../core/core.dart';
import '../util/auto_dispose.dart';
import '../util/bitmap_button.dart';
import '../util/fonts.dart';
import '../util/functions.dart';
import '../util/messaging.dart';
import '../util/shortcuts.dart';
import 'board_stack_component.dart';
import 'card_game.dart';
import 'draggable_card.dart';
import 'game_messages.dart';
import 'hot_to_play.dart';
import 'minden_game.dart';
import 'new_game_dialog.dart';
import 'soundboard.dart';
import 'stack_component.dart';

class AutoSolver extends Component with AutoDispose {
  bool active = false;
  Card? auto_solve;

  @override
  void onLoad() {
    super.onLoad();
    minden_game.on_auto_solve = () {
      if (!minden_game.settings.auto_finish) return;
      minden_game.game_locked = true;
      active = true;
    };
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!active) return;

    final next = minden_game.next_auto_solve;
    if (identical(auto_solve, next)) return;

    auto_solve = next;
    if (next == null) {
      minden_game.game_locked = false;
      active = false;
    } else {
      sendMessage(AnimateAutoSolve(next));
    }
  }
}

class GameScreen extends PositionComponent with AutoDispose, HasAutoDisposeShortcuts {
  GameScreen() : super(size: game_size);

  Image? _button;

  @override
  onLoad() async {
    try {
      await minden_game.load();
      logInfo('game state restored');
    } catch (it, trace) {
      logError('failed restoring game state - ignored: $it', trace);
      minden_game.new_game();
    }

    add(AutoSolver());

    _button ??= await image('button_plain.png');

    await add(RectangleComponent(size: size, paint: pixelPaint()..color = minden_green));

    final cards = await sheetIWH('cards.png', 72, 92, spacing: 2, margin: 1);

    final CardGame card_game = minden_game.settings.card_game;

    final pos = ace_stacks_offset;
    for (final (index, ace_stack) in minden_game.ace_stacks.indexed) {
      final stack = AceStackComponent(cards_sheet: cards, stack: ace_stack, card_game: card_game);
      stack.position = pos;
      await add(stack);
      if (index < 8) {
        pos.x += stack.width + stack_gap.x;
      } else {
        pos.y += stack.height + stack_gap.y;
      }
    }

    pos.setFrom(play_stacks_offset);
    for (final play_stack in minden_game.play_stacks) {
      final stack = PlayStackComponent(cards_sheet: cards, stack: play_stack, card_game: card_game);
      stack.position = pos;
      await add(stack);
      pos.x += stack.width + stack_gap.x;
    }

    await add(BoardStackComponent(cards_sheet: cards, stack: minden_game.board_stack)..position = board_stack_offset);

    late NewGameDialog new_game_dialog;

    await add(_make_button('Undo', 9, 1, 'u', () => minden_game.undo()));
    await add(_make_button('Try Again', 77, 1, '<A-t>', () => new_game_dialog.try_again()));
    await add(_make_button('New Game', 200, 1, '<A-n>', () => new_game_dialog.new_game()));
    await add(_make_button('How To Play', 322, 1, '<A-h>', () => add(HowToPlay())));

    await add(VolumeComponent(
      bg_nine_patch: _button,
      label: 'Music Volume',
      position: Vector2(746, 1),
      size: Vector2(112, 32),
      anchor: Anchor.topRight,
      key_down: '[',
      key_up: ']',
      change: (double volume) => soundboard.music = volume,
      volume: () => soundboard.music,
    ));

    await soundboard.preload();
    await soundboard.play_music('music/city_of_minden.ogg');

    await add(new_game_dialog = NewGameDialog());
  }

  BitmapButton _make_button(String text, double x, double y, String shortcut, Function() onTap) => BitmapButton(
        bgNinePatch: _button,
        text: text,
        position: Vector2(x, y),
        font: menu_font,
        fontScale: 0.5,
        shortcuts: [shortcut],
        anchor: Anchor.topLeft,
        onTap: (_) => onTap(),
      );
}
