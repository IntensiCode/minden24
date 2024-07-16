import 'package:flame/components.dart';
import 'package:flame/sprite.dart';

import '../core/core.dart';
import 'draggable_card.dart';
import 'minden_game.dart';

class BoardStackComponent extends PositionComponent {
  BoardStackComponent({required SpriteSheet cards_sheet, required BoardStack stack})
      : _cards_sheet = cards_sheet,
        _stack = stack {
    size.x = 8 * cards_sheet.srcSize.x + 7 * stack_gap.x;
    size.y = 2 * cards_sheet.srcSize.y + 1 * stack_gap.y;
  }

  final SpriteSheet _cards_sheet;
  final BoardStack _stack;

  @override
  Future onLoad() async {
    await super.onLoad();

    // TODO optimize recreate + snapshot OMG :-D

    final board_grid_size = Vector2(
      _cards_sheet.srcSize.x + stack_gap.x + stack_card_offset * 8,
      _cards_sheet.srcSize.y + stack_gap.y + stack_card_offset * 8,
    );

    final mine = <Component>[];
    _stack.when_changed = () {
      parent!.removeAll(mine);
      mine.clear(); // TODO optimize recreate + snapshot OMG :-D

      for (final (height, layer) in _stack.layers.indexed) {
        for (final it in layer.placed_cards) {
          final position = Vector2.copy(it.place);
          position.multiply(board_grid_size);
          position.x += height * stack_card_offset;
          position.y += height * stack_card_offset;
          position.add(this.position);

          final card_sprite = _cards_sheet.sprite_for_card(it.card);
          final card_component = DraggableCardComponent(
            sprite: card_sprite,
            position: position,
            container: _stack,
            batch: [it.card],
            is_free_to_move: it.is_free_to_move,
          );
          parent!.add(card_component);

          mine.add(card_component);
        }
      }
    };
  }
}
