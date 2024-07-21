import 'package:flame/components.dart';

import '../core/core.dart';
import 'card_game.dart';
import 'draggable_card.dart';
import 'minden_game.dart';

class AnimateAutoSolve with Message {
  AnimateAutoSolve(this.card);

  final Card card;
}

class AnimateToTarget with Message {
  AnimateToTarget(this.batch, this.target, this.on_complete);

  final List<DraggableCardComponent> batch;
  final TargetStack target;
  final void Function() on_complete;
}

class FindDragTarget with Message {
  FindDragTarget({
    required this.at,
    required this.not_in,
    required this.when_found,
  });

  final Vector2 at;
  final SourceStack not_in;
  final void Function(TargetStack stack) when_found;
}

class PickCards with Message {}

class PickMusic with Message {}

class PlayEndMusic with Message {
  PlayEndMusic(this.when_done);

  Hook when_done;
}

class RefreshCards with Message {}
