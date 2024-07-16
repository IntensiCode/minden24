import 'package:collection/collection.dart';
import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

import 'core/core.dart';
import 'core/screens.dart';
import 'game/game_screen.dart';
import 'util/extensions.dart';
import 'util/messaging.dart';
import 'web_play_screen.dart';

class MainController extends World implements ScreenNavigation {
  final _stack = <Screen>[];

  @override
  onLoad() async => messaging.listen<ShowScreen>((it) => showScreen(it.screen));

  @override
  void onMount() {
    if (dev && !kIsWeb) {
      showScreen(Screen.game);
    } else if (kIsWeb) {
      add(WebPlayScreen());
    } else {
      showScreen(Screen.game);
    }
  }

  @override
  void popScreen() {
    logVerbose('pop screen with stack=$_stack and children=${children.map((it) => it.runtimeType)}');
    _stack.removeLastOrNull();
    showScreen(_stack.lastOrNull ?? Screen.game);
  }

  @override
  void pushScreen(Screen it) {
    logVerbose('push screen $it with stack=$_stack and children=${children.map((it) => it.runtimeType)}');
    if (_stack.lastOrNull == it) throw 'stack already contains $it';
    _stack.add(it);
    showScreen(it);
  }

  Screen? _triggered;
  StackTrace? _previous;

  @override
  void showScreen(Screen screen, {bool skip_fade_out = false, bool skip_fade_in = false}) {
    if (_triggered == screen) {
      logError('duplicate trigger ignored: $screen', StackTrace.current);
      logError('previous trigger', _previous);
      return;
    }
    _triggered = screen;
    _previous = StackTrace.current;

    if (skip_fade_out) logInfo('show $screen');
    logVerbose('screen stack: $_stack');
    logVerbose('children: ${children.map((it) => it.runtimeType)}');

    if (!skip_fade_out && children.isNotEmpty) {
      children.last.fadeOutDeep(and_remove: true);
      children.last.removed.then((_) {
        if (_triggered == screen) {
          _triggered = null;
        } else if (_triggered != screen) {
          return;
        }
        logInfo('show $screen');
        showScreen(screen, skip_fade_out: skip_fade_out, skip_fade_in: skip_fade_in);
      });
    } else {
      final it = added(_makeScreen(screen));
      if (screen != Screen.game && !skip_fade_in) {
        it.mounted.then((_) => it.fadeInDeep());
      }
    }
  }

  Component _makeScreen(Screen it) => switch (it) {
        Screen.game => GameScreen(),
      };
}
