import '../util/storage.dart';
import 'card_game.dart';

enum Difficulty {
  easy,
  normal,
  hard,
  very_hard;

  String save() => name;

  static Difficulty load(String name) => Difficulty.values.firstWhere((it) => it.name == name);
}

class MindenSettings {
  MindenSettings({
    this.difficulty = Difficulty.normal,
    this.game_seed = 0,
    CardGame? card_game,
    this.easy_shuffle = true,
    this.tap_to_auto_place = true,
    this.auto_finish = true,
    this.batch_drag = true,
  }) : card_game = card_game ?? CardGame.default_sets();

  final Difficulty difficulty;
  final int game_seed;
  final CardGame card_game;
  final bool easy_shuffle;
  final bool tap_to_auto_place;
  final bool auto_finish;
  final bool batch_drag;

  MindenSettings copy({
    Difficulty? difficulty,
    int? game_seed,
    CardGame? card_game,
    bool? easy_shuffle,
    bool? tap_to_auto_place,
    bool? auto_finish,
    bool? batch_drag,
  }) =>
      MindenSettings(
        difficulty: difficulty ?? this.difficulty,
        game_seed: game_seed ?? this.game_seed,
        card_game: card_game ?? this.card_game,
        easy_shuffle: easy_shuffle ?? this.easy_shuffle,
        tap_to_auto_place: tap_to_auto_place ?? this.tap_to_auto_place,
        auto_finish: auto_finish ?? this.auto_finish,
        batch_drag: batch_drag ?? this.batch_drag,
      );

  GameData save() => {
        'difficulty': difficulty.save(),
        'game_seed': game_seed,
        'card_game': card_game.save(),
        'easy_shuffle': easy_shuffle,
        'tap_to_auto_place': tap_to_auto_place,
        'auto_finish': auto_finish,
        'batch_drag': batch_drag,
      };

  static MindenSettings load(GameData data) => MindenSettings(
        difficulty: Difficulty.load(data['difficulty']),
        game_seed: data['game_seed'],
        card_game: CardGame.load(data['card_game']),
        easy_shuffle: data['easy_shuffle'],
        tap_to_auto_place: data['tap_to_auto_place'],
        auto_finish: data['auto_finish'],
        batch_drag: data['batch_drag'],
      );
}
