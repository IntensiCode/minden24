import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';

import '../core/core.dart';
import '../util/auto_dispose.dart';
import '../util/on_message.dart';
import 'card_game.dart';
import 'cards_selection.dart';
import 'draggable_card.dart';
import 'game_messages.dart';
import 'minden_game.dart';

abstract class StackComponent<T extends CardStack> extends PositionComponent with AutoDispose {
  StackComponent({required T stack}) : _stack = stack;

  final T _stack;

  final _mine = <Component>[];

  @override
  Future onLoad() async {
    super.onLoad();

    size.x = card_width + card_game.number_of_cards_per_set * x_spacing;
    size.y = card_height + card_game.number_of_cards_per_set * y_spacing;

    onMessage<AnimateToTarget>((it) {
      if (!identical(it.target, _stack)) return;

      final top_left = position.clone();
      final stacking = _stack.cards.length;
      top_left.x += stacking * x_spacing;
      top_left.y += stacking * y_spacing;

      for (final card in it.batch) {
        card.is_free_to_move = false;
        card.priority = 1;
        final distance = card.position.distanceTo(top_left);
        card.add(MoveToEffect(top_left, EffectController(duration: distance / 5000), onComplete: () {
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
      final size_x = card_width + stacking * x_spacing - x_spacing;
      final size_y = card_height + stacking * y_spacing;
      if (it.at.x < position.x || it.at.x > position.x + size_x) return;
      if (it.at.y < position.y || it.at.y > position.y + size_y) return;

      it.when_found(_stack);
    });

    onMessage<RefreshCards>((it) => _recreate());

    _stack.when_changed = () => _recreate();
  }

  // TODO optimize recreate + snapshot

  void _recreate() {
    parent!.removeAll(_mine);
    _mine.clear();

    final scale = Vector2(
      card_width / active_cards.getSpriteById(0).srcSize.x,
      card_height / active_cards.getSpriteById(0).srcSize.y,
    );

    removeAll(children);
    add(SpriteComponent(sprite: placeholder, scale: scale));

    for (final (index, card) in _stack.cards.indexed) {
      final position = Vector2(index * x_spacing, index * y_spacing);

      final batch = _stack.cards.toList();
      batch.removeRange(0, index);

      final sprite = active_cards.sprite_for_card(card);
      final PositionComponent component;
      if (_stack case SourceStack it) {
        component = DraggableCardComponent(
          sprite: sprite,
          position: position,
          container: it,
          batch: batch,
          is_free_to_move: true,
          make_batch_peers: _make_batch_peers,
        );
      } else {
        component = SpriteComponent(sprite: sprite, position: position);
      }
      component.position.add(this.position);
      component.scale.setFrom(scale);

      parent!.add(component);
      _mine.add(component);
    }
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
  AceStackComponent({required super.stack});

  @override
  Sprite get placeholder => active_cards.ace_placeholder;

  @override
  double get y_spacing => x_spacing;
}

class PlayStackComponent extends StackComponent<PlayStack> {
  PlayStackComponent({required super.stack});

  @override
  Sprite get placeholder => active_cards.play_placeholder;

  @override
  double get y_spacing => 18;
}
