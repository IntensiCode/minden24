import 'dart:math';

import 'package:collection/collection.dart';
import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/extensions.dart';
import 'package:flame/sprite.dart';
import 'package:kart/kart.dart' hide KtIterableExtension;

import '../util/extensions.dart';
import '../util/storage.dart';
import 'card_game.dart';
import 'minden_settings.dart';

typedef Hook = void Function();
typedef AutoPlacement = (TargetStack, void Function());

final minden_game = MindenGame();

final board_stack_places = {
  Difficulty.normal: [14, 6],
  Difficulty.hard: [12, 5],
  Difficulty.very_hard: [10, 4],
};

int odd_board_stack_places(Difficulty difficulty) => switch (difficulty) {
      Difficulty.easy => 16,
      Difficulty.normal => 14,
      Difficulty.hard => 12,
      Difficulty.very_hard => 10,
    };

int even_board_stack_places(Difficulty difficulty) => switch (difficulty) {
      Difficulty.easy => 7,
      Difficulty.normal => 6,
      Difficulty.hard => 5,
      Difficulty.very_hard => 4,
    };

mixin TargetStack {
  bool can_add_card(CardGame card_game, Card card);

  void add_card(Card card);
}

mixin SourceStack {
  void remove_card(Card card);
}

abstract class CardStack with TargetStack {
  final List<Card> _cards = [];

  Hook _when_changed = () {};

  set when_changed(Hook value) {
    _when_changed = value;
    _when_changed();
  }

  void new_game() {
    _cards.clear();
    _when_changed();
  }

  bool get is_empty => _cards.isEmpty;

  Iterable<Card> get cards => _cards;

  @override
  bool can_add_card(CardGame card_game, Card card);

  @override
  void add_card(Card card) {
    _cards.add(card);
    _when_changed();
  }

  String save() => toString();

  void load(String data) {
    _cards.clear();
    if (data.isNotEmpty) {
      _cards.addAll(data.split(',').map((it) => Card.load(it)).toList());
    }
    _when_changed();
  }

  @override
  bool operator ==(Object other) => toString() == other.toString();

  @override
  int get hashCode => toString().hashCode;

  @override
  String toString() => _cards.join(',');
}

class AceStack extends CardStack {
  @override
  bool can_add_card(CardGame card_game, Card card) {
    if (is_empty) {
      return card.value == CardValue.ace;
    } else {
      return card_game.are_same_set_ascending_order(_cards.last, card);
    }
  }
}

class PlayStack extends CardStack with SourceStack {
  @override
  bool can_add_card(CardGame card_game, Card card) {
    if (is_empty) {
      return true;
    } else {
      return card_game.are_different_color_and_descending_order(_cards.last, card);
    }
  }

  @override
  void remove_card(Card card) {
    if (!identical(card, _cards.last)) throw 'cannot remove $card from $this';
    _cards.removeLast();
    _when_changed();
  }
}

/// a placed card on a board stack layer.
///
/// has a relative place according to odd/even layer type:
/// - for odd layers, the places are (0, 0), (0, 1), (1, 0), (1, 1), ... (7, 0), (7, 1).
/// - for even layers, the places are (0.5, 0.5), (1.5, 0.5), (2.5, 0.5), ... (6.5, 0.5).
class PlacedCard {
  PlacedCard({required this.card, required this.place, this.is_free_to_move = false});

  final Vector2 place;
  final Card card;
  bool is_free_to_move;

  String save() => '${card.save()}[${place.x},${place.y}]${is_free_to_move ? 'f' : ''}';

  static PlacedCard load(String data) {
    final xy = data.split(RegExp('\\[|\\]'))[1].split(',').map((it) => double.parse(it));
    return PlacedCard(
      place: Vector2(xy.first, xy.last),
      card: Card.load(data[0] + data[1]),
      is_free_to_move: data.endsWith('f'),
    );
  }

  @override
  bool operator ==(Object other) => toString() == other.toString();

  @override
  int get hashCode => toString().hashCode;

  @override
  String toString() => '$card[${place.x},${place.y}]${is_free_to_move ? 'f' : ''}';
}

sealed class BoardStackLayer {
  BoardStackLayer({required int places}) : _cards = List.filled(places, null);

  BoardStackLayer._loaded({required List<PlacedCard?> cards}) : _cards = cards;

  final List<PlacedCard?> _cards;

  Vector2 _place_for_index(int index);

  int get number_of_placed_cards => _cards.whereNotNull().length;

  Iterable<PlacedCard> get placed_cards => _cards.whereNotNull();

  bool can_add_card() => _cards.any((it) => it == null);

  void add_card(Card card) {
    final which = _cards.indexWhere((it) => it == null);
    if (which == -1) throw 'cannot add to full layer: $this';
    _cards[which] = PlacedCard(card: card, place: _place_for_index(which), is_free_to_move: false);
  }

  void center_cards() {
    final non_null = _cards.whereNotNull().toList();
    if (non_null.isEmpty) return;

    final offset = (_cards.length - non_null.length) ~/ 2;
    _cards.fill(null);
    _cards.setRange(offset, offset + non_null.length, non_null);

    for (final (index, it) in non_null.indexed) {
      it.place.setFrom(_place_for_index(offset + index));
    }
  }

  void mark_all_cards_free() {
    for (final it in _cards) {
      it?.is_free_to_move = true;
    }
  }

  void mark_free_using(bool Function(Vector2) is_covered) {
    for (final it in _cards) {
      if (it == null) continue;
      it.is_free_to_move = !is_covered(it.place);
    }
  }

  bool is_covering(Vector2 place) {
    for (final it in _cards) {
      if (it == null) continue;
      final dx = (place.x - it.place.x).abs();
      final dy = (place.y - it.place.y).abs();
      if (dx < 1 && dy < 1) return true;
    }
    return false;
  }

  bool has_card(Card card) => _cards.any((it) => identical(it?.card, card));

  void remove_card(Card card) {
    final index = _cards.indexWhere((it) => identical(it?.card, card));
    if (index == -1) throw 'cannot find card $card to be removed from $this';
    _cards[index] = null;
  }

  String save() {
    final type = switch (this) {
      OddBoardStackLayer() => 'odd',
      EvenBoardStackLayer() => 'even',
    };
    return '$type:${_cards.map((it) => it?.save() ?? '__').join('|')}';
  }

  static BoardStackLayer load(String data) {
    final type_and_cards = data.split(':');
    final cards = type_and_cards[1].split('|').map((it) => it == '__' ? null : PlacedCard.load(it)).toList();
    return switch (type_and_cards[0]) {
      'odd' => OddBoardStackLayer._loaded(cards: cards),
      'even' => EvenBoardStackLayer._loaded(cards: cards),
      _ => throw 'unsupported board stack layer type: ${type_and_cards[0]}',
    };
  }

  @override
  bool operator ==(Object other) => toString() == other.toString();

  @override
  int get hashCode => toString().hashCode;

  @override
  String toString() => _cards.join(',');
}

class OddBoardStackLayer extends BoardStackLayer {
  OddBoardStackLayer({required super.places});

  OddBoardStackLayer._loaded({required super.cards}) : super._loaded();

  @override
  Vector2 _place_for_index(int index) => Vector2((index ~/ 2).toDouble(), index % 2);
}

class EvenBoardStackLayer extends BoardStackLayer {
  EvenBoardStackLayer({required super.places});

  EvenBoardStackLayer._loaded({required super.cards}) : super._loaded();

  @override
  Vector2 _place_for_index(int index) => Vector2(0.5 + index.toDouble(), 0.5);
}

// stack of layers of cards. odd layers have 16 cards, even layers have 7. cards from upper layers block those
// from the layer below.
class BoardStack with SourceStack {
  BoardStack() {
    new_game(Difficulty.hard);
  }

  late Difficulty _difficulty;
  late List<BoardStackLayer> _layers;

  Hook _when_changed = () {};

  set when_changed(Hook value) {
    _when_changed = value;
    _when_changed();
  }

  int get number_of_layers => _layers.length;

  int get number_of_cards_in_top_layer => _layers.isEmpty ? 0 : _layers.last.number_of_placed_cards;

  Iterable<Card> get all_remaining_cards => _layers.expand((it) => it._cards).mapNotNull((it) => it?.card);

  Iterable<BoardStackLayer> get layers => _layers;

  void new_game(Difficulty difficulty) {
    _difficulty = difficulty;
    _layers = [];
    _when_changed();
  }

  // adds another empty layer. adds an OddBoardStackLayer10 if this layer is odd, an EvenBoardStackLayer4 otherwise.
  // counting starts at 1.
  void add_empty_layer() {
    final next_layer_number = _layers.length + 1;
    if (next_layer_number.isOdd) {
      _layers.add(OddBoardStackLayer(places: odd_board_stack_places(_difficulty)));
    } else {
      _layers.add(EvenBoardStackLayer(places: even_board_stack_places(_difficulty)));
    }
  }

  // check if the top most layer has room for another card.
  bool can_add_card_to_top_most_layer() {
    if (_layers.isEmpty) return false;
    return _layers.last.can_add_card();
  }

  // adds a card to the top-most layer. throws if no more room in this layer.
  void add_card(Card card) {
    if (_layers.isEmpty) throw 'no layers in the board stack';
    _layers.last.add_card(card);
  }

  void center_top_layer_cards() {
    if (_layers.isEmpty) throw 'no layers in the board stack';
    _layers.last.center_cards();
  }

  void update_free_state() {
    if (_layers.isEmpty) throw 'no layers in the board stack';
    _layers.last.mark_all_cards_free();
    for (var i = _layers.length - 2; i >= 0; i--) {
      final layer = _layers[i];
      final above = _layers[i + 1];
      layer.mark_free_using((place) => above.is_covering(place));
    }
    _when_changed(); // TODO per layer? as a quick perf fix/opt?
  }

  @override
  void remove_card(Card card) {
    logInfo('remove card $card');

    if (_layers.isEmpty) throw 'no layers in the board stack';

    for (final it in _layers.reversed) {
      if (it.has_card(card)) {
        it.remove_card(card);
        update_free_state();

        while (_layers.lastOrNull?.number_of_placed_cards == 0) {
          logInfo('removing empty top layer');
          _layers.removeLast();
        }

        return;
      }
    }

    throw 'cannot find card $card to be removed from $this';
  }

  GameData save() => {'difficulty': _difficulty.name, 'layers': _layers.map((it) => it.save()).toList()};

  void load(GameData data) {
    _difficulty = Difficulty.values.firstWhere((it) => it.name == data['difficulty']);
    _layers.clear();
    _layers.addAll((data['layers'] as List).map((it) => BoardStackLayer.load(it)).toList());
    _when_changed();
  }

  @override
  bool operator ==(Object other) => toString() == other.toString();

  @override
  int get hashCode => toString().hashCode;

  @override
  String toString() => _layers.join('\n');
}

/// the minden game has 12 ace stacks, 8 play stacks, and 1 board stack. the game starts with three card sets shuffled
/// in the board stack. that is, the board stack is initially full, all ace and play stacks are empty. because of the
/// three card sets, the game has 12 aces. hence, the 12 ace stacks. a card set has cards from seven to ace.
///
/// the game is played by putting cards in the order ace, seven, eight, nine, ten, jack, queen, king onto the ace
/// stacks. at any time cards can be placed onto the play stacks. on the play stack the order is reversed, and every
/// other card has to have a different color. the order is: king, queen, jack, ten, nine, eight, seven, ace.
///
/// the player can take cards only from the board stack or the play stacks. cards from the board stack can be taken
/// only layer by layer. cards from a layer block cards from the layer below. play stack cards can be taken from any
/// play stack, but only the top-most card can be taken.
class MindenGame {
  bool game_locked = false;

  var settings = MindenSettings();

  final board_stack = BoardStack();

  late final List<AceStack> ace_stacks = List.generate(12, (_) => AceStack(), growable: false);
  late final List<PlayStack> play_stacks = List.generate(8, (_) => PlayStack(), growable: false);

  void Function() on_auto_solve = () {};

  bool get is_solved => all_remaining_cards.isEmpty;

  Card? get next_auto_solve => all_remaining_cards.firstOrNull;

  Iterable<Card> get all_remaining_cards {
    final all = <Card>[];
    all.addAll(board_stack.all_remaining_cards);
    all.addAll(play_stacks.expand((it) => it.cards));
    all.sort((a,b) => a.value.index - b.value.index);
    return all;
  }

  void new_game({MindenSettings? new_game_settings}) {
    settings = new_game_settings ?? settings;
    board_stack.new_game(settings.difficulty);
    ace_stacks.forEach((it) => it.new_game());
    play_stacks.forEach((it) => it.new_game());

    final card_games = [settings.card_game, settings.card_game, settings.card_game];
    logInfo('${card_games.length} card games');
    logInfo('${card_games.first.sets.length} card sets per games');
    logInfo('${card_games.first.number_of_cards_per_set} cards per card set');

    if (settings.easy_shuffle) {
      _easy_shuffle(card_games, settings.game_seed, settings.difficulty);
    } else {
      _full_shuffle(card_games, settings.game_seed, settings.difficulty);
    }

    board_stack.center_top_layer_cards();
    board_stack.update_free_state();

    logInfo(board_stack);
  }

  void _easy_shuffle(List<CardGame> card_games, int game_seed, Difficulty? difficulty) {
    final card_sets = card_games.map((it) => it.sets).expand((it) => it).toList();
    final cards = card_sets.expand((it) => it.cards).toList();
    logInfo('${cards.length} cards all together');
    logInfo(cards);
    final rng = Random(game_seed);
    final first_half = cards.sublist(0, cards.length ~/ 6);
    final second_half = cards.sublist(first_half.length);
    first_half.shuffle(rng);
    second_half.shuffle(rng);
    _fill_board_stack(first_half, difficulty);
    _fill_board_stack(second_half, difficulty);
  }

  void _fill_board_stack(List<Card> cards, Difficulty? difficulty) {
    for (final card in cards) {
      if (!board_stack.can_add_card_to_top_most_layer()) {
        board_stack.add_empty_layer();
      } else if (difficulty == Difficulty.hard) {
        if (board_stack.number_of_layers == 11) {
          if (board_stack.number_of_cards_in_top_layer == 8) {
            logInfo('extra layer');
            board_stack.center_top_layer_cards();
            board_stack.add_empty_layer();
          }
        }
      }
      board_stack.add_card(card);
    }
  }

  void _full_shuffle(List<CardGame> card_games, int game_seed, Difficulty? difficulty) {
    final card_sets = card_games.map((it) => it.sets).expand((it) => it).toList();
    final cards = card_sets.expand((it) => it.cards).toList();
    logInfo('${cards.length} cards all together');
    logInfo(cards);
    cards.shuffle(Random(game_seed));

    for (final card in cards) {
      if (!board_stack.can_add_card_to_top_most_layer()) {
        board_stack.add_empty_layer();
      } else if (difficulty == Difficulty.hard) {
        if (board_stack.number_of_layers == 11) {
          if (board_stack.number_of_cards_in_top_layer == 8) {
            logInfo('extra layer');
            board_stack.center_top_layer_cards();
            board_stack.add_empty_layer();
          }
        }
      }
      board_stack.add_card(card);
    }
  }

  Hook? make_placement_for({
    required Card card,
    required SourceStack from,
    required TargetStack to,
  }) {
    if (to.can_add_card(settings.card_game, card)) {
      return () {
        from.remove_card(card);
        to.add_card(card);
        save();
      };
    }
    return null;
  }

  Hook? make_batch_placement_for({required List<Card> batch, required SourceStack from, required TargetStack to}) {
    if (to.can_add_card(settings.card_game, batch.first)) {
      return () {
        for (final card in batch.reversed) {
          from.remove_card(card);
        }
        for (final card in batch) {
          to.add_card(card);
        }
        save();
      };
    }
    return null;
  }

  AutoPlacement? find_play_stack_for({required List<Card> batch, required SourceStack from}) {
    for (final to in play_stacks) {
      if (to.can_add_card(settings.card_game, batch.first)) {
        return (
          to,
          () {
            for (final card in batch.reversed) {
              from.remove_card(card);
            }
            for (final card in batch) {
              to.add_card(card);
            }
            save();
          }
        );
      }
    }
    return null;
  }

  AutoPlacement? find_auto_placement_for({required Card card, required SourceStack from}) {
    for (final it in ace_stacks) {
      if (it.can_add_card(settings.card_game, card)) {
        return (
          it,
          () {
            from.remove_card(card);
            it.add_card(card);
            save();
          }
        );
      }
    }
    for (final it in play_stacks) {
      if (it.can_add_card(settings.card_game, card)) {
        return (
          it,
          () {
            from.remove_card(card);
            it.add_card(card);
            save();
          }
        );
      }
    }
    return null;
  }

  void undo() {
    if (_undo.isEmpty) return;
    load_state(_pending_undo = _undo.removeLast());
  }

  final _undo = <GameData>[];
  GameData? _pending_undo;

  Future save() async {
    if (game_locked) return;

    if (_pending_undo != null) {
      _undo.add(_pending_undo!);
      _pending_undo = null;
    }

    logInfo('save game state');
    final data = save_state();
    await save_data('minden_game', data);

    _pending_undo = data;

    if (board_stack._layers.length == 1) {
      on_auto_solve();
    }
  }

  Future load() async {
    final data = await load_data('minden_game');
    load_state(data!);
  }

  GameData save_state() => {
        'settings': settings.save(),
        'board_stack': board_stack.save(),
        'ace_stacks': ace_stacks.map((it) => it.save()).toList(),
        'play_stacks': play_stacks.map((it) => it.save()).toList(),
      };

  void load_state(GameData data) {
    settings = MindenSettings.load(data['settings']);
    board_stack.load(data['board_stack']);
    for (final (index, it) in ace_stacks.indexed) {
      it.load(data['ace_stacks'][index]);
    }
    for (final (index, it) in play_stacks.indexed) {
      it.load(data['play_stacks'][index]);
    }
  }

  @override
  bool operator ==(Object other) => toString() == other.toString();

  @override
  int get hashCode => toString().hashCode;

  @override
  String toString() => 'ace_stacks: $ace_stacks\nplay_stacks: $play_stacks\nboard_stack: $board_stack';
}

extension SpriteSheetExtensions on SpriteSheet {
  Sprite get ace_placeholder => getSpriteById(rows * columns - 1);

  Sprite get play_placeholder => getSpriteById(rows * columns - 2);

  Sprite sprite_for_card(final Card card) => getSpriteById(card.kind.index * columns + card.value.index);
}
