import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';

import '../core/core.dart';
import '../util/auto_dispose.dart';
import '../util/extensions.dart';
import '../util/messaging.dart';
import '../util/on_message.dart';
import 'card_game.dart';
import 'card_overlay.dart';
import 'game_messages.dart';
import 'minden_game.dart';
import 'soundboard.dart';

class DraggableCardComponent extends SpriteComponent with AutoDispose, TapCallbacks, DragCallbacks {
  DraggableCardComponent({
    required Sprite sprite,
    required Vector2 position,
    required this.container,
    required this.batch,
    required this.is_free_to_move,
    this.make_batch_peers,
  }) : super(sprite: sprite, position: position) {
    if (!is_free_to_move) {
      add(CardOverlay(size: size, paint: pixelPaint()..color = shadow_soft));
    }
  }

  final SourceStack container;
  final List<Card> batch;

  bool is_free_to_move;

  List<DraggableCardComponent> Function(List<Card>)? make_batch_peers;

  bool is_part_of(List<Card> batch) => batch.any((it) => identical(it, this.batch.first));

  static bool get tap_to_auto_place => minden_game.settings.tap_to_auto_place;

  static bool get batch_drag => minden_game.settings.batch_drag;

  @override
  void onMount() {
    super.onMount();
    onMessage<AnimateAutoSolve>((it) async {
      if (!identical(it.card, batch.first)) return;
      final AutoPlacement? auto_place = minden_game.find_auto_placement_for(card: it.card, from: container);
      sendMessage(AnimateToTarget([this], auto_place!.$1, () {
        auto_place.$2.call();
      }));
    });
  }

  @override
  void onTapUp(TapUpEvent event) {
    super.onTapUp(event);
    if (minden_game.game_locked) return;
    if (!is_free_to_move) return;
    if (!tap_to_auto_place) return;

    final AutoPlacement? auto_place;
    if (batch.length > 1) {
      auto_place = minden_game.find_play_stack_for(batch: batch, from: container);
    } else {
      auto_place = minden_game.find_auto_placement_for(card: batch.single, from: container);
    }

    if (auto_place != null) {
      minden_game.game_locked = true;
      final batch_peers = make_batch_peers?.call(batch) ?? [this];
      sendMessage(AnimateToTarget(batch_peers, auto_place.$1, () {
        minden_game.game_locked = false;
        auto_place?.$2.call();
      }));
    }

    soundboard.play(auto_place != null ? Sound.card_placed : Sound.cannot_do);
  }

  static final _highlight_paint = pixelPaint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..color = green;

  Vector2? _drag_reset;
  Vector2? _drag_check;
  late List<DraggableCardComponent> _batch_peers;

  Component? _highlight;
  Hook? _drag_placement;

  void _start_drag(Vector2 drag_point) {
    _drag_reset = position.clone();
    _drag_check = position.clone();
    _drag_check?.add(drag_point);
    priority = 1;
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    if (minden_game.game_locked) return;
    if (!is_free_to_move) return;
    if (batch.length > 1 && !batch_drag) return;
    _batch_peers = make_batch_peers?.call(batch) ?? [this];
    for (final it in _batch_peers) {
      it._start_drag(event.localPosition);
    }
  }

  void _update_drag(Vector2 delta, bool passive) {
    position += delta;
    _drag_check?.add(delta);

    if (passive) return;

    TargetStack? drag_target;
    sendMessage(FindDragTarget(at: _drag_check!, not_in: container, when_found: (it) => drag_target = it));

    _drag_placement = null;
    if (drag_target case TargetStack it) {
      if (batch.length > 1) {
        _drag_placement = minden_game.make_batch_placement_for(batch: batch, from: container, to: it);
      } else {
        _drag_placement = minden_game.make_placement_for(card: batch.single, from: container, to: it);
      }
    }

    if (_drag_placement != null) {
      _highlight ??= added(CardOverlay(size: size, paint: _highlight_paint));
    } else if (_highlight != null) {
      remove(_highlight!);
      _highlight = null;
    }
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    if (minden_game.game_locked) return;
    if (!is_free_to_move || _drag_check == null) return;
    for (final it in _batch_peers) {
      it._update_drag(event.localDelta, it != _batch_peers.first);
    }
  }

  void _end_drag(bool passive) {
    is_free_to_move = false;

    if (_drag_placement == null || passive) {
      soundboard.play(Sound.cannot_do);
      add(MoveToEffect(_drag_reset!, EffectController(duration: 0.1), onComplete: () {
        is_free_to_move = true;
        priority = 0;
      }));
    } else if (_drag_placement != null) {
      soundboard.play(Sound.card_placed);
      _drag_placement?.call();
    }

    _drag_reset = null;
    _drag_check = null;
    _drag_placement = null;

    if (_highlight != null) {
      remove(_highlight!);
      _highlight = null;
    }
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    if (minden_game.game_locked) return;
    if (!is_free_to_move || _drag_reset == null) return;
    for (final it in _batch_peers) {
      it._end_drag(it != _batch_peers.first);
    }
  }

  @override
  String toString() => "$batch:${super.toString()}";
}
