import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/sprite.dart';

import '../core/core.dart';
import '../util/auto_dispose.dart';
import '../util/on_message.dart';
import 'card_game.dart';
import 'draggable_card.dart';
import 'game_messages.dart';
import 'minden_game.dart';

abstract class StackComponent<T extends CardStack> extends PositionComponent with AutoDispose {
  StackComponent({
    required SpriteSheet cards_sheet,
    required T stack,
    required CardGame card_game,
  })  : _cards_sheet = cards_sheet,
        _stack = stack {
    size.x = cards_sheet.srcSize.x + card_game.number_of_cards_per_set * x_spacing;
    size.y = cards_sheet.srcSize.y + card_game.number_of_cards_per_set * y_spacing;
  }

  final SpriteSheet _cards_sheet;
  final T _stack;

  final _mine = <Component>[];

  @override
  Future onLoad() async {
    super.onLoad();

    onMessage<AnimateToTarget>((it) {
      if (!identical(it.target, _stack)) return;

      final top_left = position.clone();
      final stacking = _stack.cards.length;
      top_left.x += stacking * x_spacing;
      top_left.y += stacking * y_spacing;

      for (final card in it.batch) {
        card.is_free_to_move = false;
        card.priority = 1;
        card.add(MoveToEffect(top_left, EffectController(duration: 0.1), onComplete: () {
          card.is_free_to_move = true;
          card.priority = 0;
          if (card == it.batch.last) it.on_complete();
        }));

        top_left.x += x_spacing;
        top_left.y += y_spacing;
      }
    });

    onMessage<FindDragTarget>((it) {
      if (it.not_in == _stack) return;

      final stacking = _stack.cards.length;
      final size_x = _cards_sheet.srcSize.x + stacking * x_spacing - x_spacing;
      final size_y = _cards_sheet.srcSize.y + stacking * y_spacing;
      if (it.at.x < position.x || it.at.x > position.x + size_x) return;
      if (it.at.y < position.y || it.at.y > position.y + size_y) return;

      it.when_found(_stack);
    });

    // TODO optimize recreate + snapshot

    _stack.when_changed = () {
      parent!.removeAll(_mine);
      _mine.clear();

      if (children.isEmpty) add(SpriteComponent(sprite: placeholder));

      for (final (index, card) in _stack.cards.indexed) {
        final position = Vector2(index * x_spacing, index * y_spacing);

        final batch = _stack.cards.toList();
        batch.removeRange(0, index);

        final PositionComponent component;
        if (_stack case SourceStack it) {
          component = DraggableCardComponent(
            sprite: _cards_sheet.sprite_for_card(card),
            position: position,
            container: it,
            batch: batch,
            is_free_to_move: true,
            make_batch_peers: _make_batch_peers,
          );
        } else {
          component = SpriteComponent(sprite: _cards_sheet.sprite_for_card(card), position: position);
        }
        component.position.add(this.position);

        parent!.add(component);
        _mine.add(component);
      }
    };
  }

  List<DraggableCardComponent> _make_batch_peers(List<Card> batch) {
    logInfo('make_batch_peers: $batch');
    final all_draggable_cards = _mine.whereType<DraggableCardComponent>();
    return all_draggable_cards.where((it) => it.is_part_of(batch)).toList();
  }

  Sprite get placeholder;

  double get x_spacing => stack_card_offset;

  double get y_spacing;
}

class AceStackComponent extends StackComponent<AceStack> {
  AceStackComponent({required super.cards_sheet, required super.stack, required super.card_game});

  @override
  Sprite get placeholder => _cards_sheet.ace_placeholder;

  @override
  double get y_spacing => x_spacing;
}

class PlayStackComponent extends StackComponent<PlayStack> {
  PlayStackComponent({required super.cards_sheet, required super.stack, required super.card_game});

  @override
  Sprite get placeholder => _cards_sheet.play_placeholder;

  @override
  double get y_spacing => 18;
}
