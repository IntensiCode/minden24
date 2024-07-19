import 'package:flame/components.dart';
import 'package:minden24/game/game_messages.dart';
import 'package:minden24/util/auto_dispose.dart';
import 'package:minden24/util/on_message.dart';

import '../core/core.dart';
import 'cards_selection.dart';
import 'draggable_card.dart';
import 'minden_game.dart';

class BoardStackComponent extends PositionComponent with AutoDispose {
  BoardStackComponent({required BoardStack stack}) : _stack = stack {
    size.x = 8 * card_width + 7 * stack_gap.x;
    size.y = 2 * card_height + 1 * stack_gap.y;
  }

  final BoardStack _stack;

  final _mine = <Component>[];

  @override
  Future onLoad() async {
    await super.onLoad();

    // TODO optimize recreate + snapshot OMG :-D

    final board_grid_size = Vector2(
      card_width + stack_gap.x + stack_card_offset * 8,
      card_height + stack_gap.y + stack_card_offset * 8,
    );
    _stack.when_changed = () => _recreate(board_grid_size);
    onMessage<RefreshCards>((it) => _recreate(board_grid_size));
  }

  void _recreate(Vector2 board_grid_size) {
    parent!.removeAll(_mine);
    _mine.clear(); // TODO optimize recreate + snapshot OMG :-D

    final scale = Vector2(
      card_width / active_cards.getSpriteById(0).srcSize.x,
      card_height / active_cards.getSpriteById(0).srcSize.y,
    );

    for (final (height, layer) in _stack.layers.indexed) {
      for (final it in layer.placed_cards) {
        final position = Vector2.copy(it.place);
        position.multiply(board_grid_size);
        position.x += height * stack_card_offset;
        position.y += height * stack_card_offset;
        position.add(this.position);

        final card_sprite = active_cards.sprite_for_card(it.card);
        final card_component = DraggableCardComponent(
          sprite: card_sprite,
          position: position,
          container: _stack,
          batch: [it.card],
          is_free_to_move: it.is_free_to_move,
        );
        card_component.scale.setFrom(scale);
        parent!.add(card_component);

        _mine.add(card_component);
      }
    }
  }
}
