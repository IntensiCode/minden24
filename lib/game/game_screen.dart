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
import 'auto_solver.dart';
import 'board_stack_component.dart';
import 'cards_selection.dart';
import 'credits.dart';
import 'end.dart';
import 'game_messages.dart';
import 'hot_to_play.dart';
import 'minden_game.dart';
import 'music_selection.dart';
import 'new_game_dialog.dart';
import 'soundboard.dart';
import 'stack_component.dart';

class GameScreen extends PositionComponent with AutoDispose, HasAutoDisposeShortcuts {
  GameScreen() : super(size: game_size);

  Image? _button;

  @override
  onLoad() async {
    minden_game.on_game_complete = () => add(End());

    try {
      await minden_game.load();
      logInfo('game state restored');
    } catch (it, trace) {
      logError('failed restoring game state - ignored: $it', trace);
      minden_game.new_game();
    }

    await add(AutoSolver());
    await add(CardsSelection());
    await add(MusicSelection());

    _button ??= await image('button_plain.png');

    await add(RectangleComponent(size: size, paint: pixelPaint()..color = minden_green));

    final pos = ace_stacks_offset;
    for (final (index, ace_stack) in minden_game.ace_stacks.indexed) {
      final stack = AceStackComponent(stack: ace_stack);
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
      final stack = PlayStackComponent(stack: play_stack);
      stack.position = pos;
      await add(stack);
      pos.x += stack.width + stack_gap.x;
    }

    await add(
      BoardStackComponent(stack: minden_game.board_stack)..position = board_stack_offset,
    );

    late NewGameDialog new_game_dialog;

    void unless_locked(Function() action) {
      if (minden_game.game_locked) return;
      action();
    }

    await add(_make_button('Undo', 9, 1, 'u', () => unless_locked(minden_game.undo)));
    await add(_make_button('Try Again', 73, 1, '<A-t>', () => unless_locked(new_game_dialog.try_again)));
    await add(_make_button('New Game', 193, 1, '<A-n>', () => unless_locked(new_game_dialog.new_game)));
    await add(_make_button('How To Play', 313, 1, '<A-h>', () => unless_locked(() => add(HowToPlay()))));
    await add(_make_button('Credits', 457, 1, '<A-k>', () => unless_locked(() => add(Credits()))));
    await add(_make_button('*', 571, 1, '<A-c>', () => unless_locked(() => sendMessage(PickCards()))));
    await add(_make_button('\u007F', 610, 1, '<A-m>', () => unless_locked(() => sendMessage(PickMusic()))));

    if (dev) await add(_make_button('End', 750, 565, '<A-e>', () => add(End())));

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
