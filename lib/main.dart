import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:minden24/util/storage.dart';
import 'package:signals_core/signals_core.dart';

import 'minden24.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SignalsObserver.instance = null;
  logLevel = kDebugMode ? LogLevel.debug : LogLevel.none;
  storage_prefix = 'minden24';
  runApp(GameWidget(game: Minden24()));
}
