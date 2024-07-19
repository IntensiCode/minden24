import 'package:flame/components.dart';

import '../util/auto_dispose.dart';
import '../util/messaging.dart';
import 'card_game.dart';
import 'game_messages.dart';
import 'minden_game.dart';

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
