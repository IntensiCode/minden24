import 'package:supercharged/supercharged.dart';

import '../util/storage.dart';

enum CardColor {
  black,
  red,
}

enum CardKind {
  clubs(id: 'C', color: CardColor.black),
  diamonds(id: 'D', color: CardColor.red),
  hearts(id: 'H', color: CardColor.red),
  spades(id: 'S', color: CardColor.black),
  ;

  final String id;
  final CardColor color;

  const CardKind({required this.id, required this.color});

  String save() => id;

  static CardKind from_id(String id) =>
      CardKind.values.firstWhere((it) => it.id == id, orElse: () => throw 'invalid id? $id');
}

enum CardValue {
  ace(id: 'A'),
  two(id: '2'),
  three(id: '3'),
  four(id: '4'),
  five(id: '5'),
  six(id: '6'),
  seven(id: '7'),
  eight(id: '8'),
  nine(id: '9'),
  ten(id: '0'),
  jack(id: 'J'),
  queen(id: 'Q'),
  king(id: 'K'),
  ;

  final String id;

  const CardValue({required this.id});

  String save() => id;

  static CardValue from_id(String id) =>
      CardValue.values.firstWhere((it) => it.id == id, orElse: () => throw 'invalid id? $id');

  static List<CardValue> get default_set => [ace, seven, eight, nine, ten, jack, queen, king];

  static List<CardValue> get full_set => [ace, two, three, four, five, six, seven, eight, nine, ten, jack, queen, king];
}

class Card {
  final CardKind kind;
  final CardValue value;

  Card({required this.kind, required this.value});

  String save() => toString();

  static Card load(String data) => Card(kind: CardKind.from_id(data[0]), value: CardValue.from_id(data[1]));

  @override
  bool operator ==(Object other) => toString() == other.toString();

  @override
  int get hashCode => toString().hashCode;

  @override
  String toString() => '${kind.id}${value.id}';
}

class CardSet {
  CardSet(CardKind kind, List<CardValue> values) {
    _kind = kind;
    _values = values;
  }

  late final CardKind _kind;
  late final List<CardValue> _values;

  CardKind get kind => _kind;

  Iterable<CardValue> get values => _values;

  int get number_of_values => _values.length;

  Iterable<Card> get cards => _values.map((it) => Card(kind: _kind, value: it));

  String save() => '${kind.id}:${_values.map((it) => it.id).join()}';

  static CardSet load(String data) {
    final kind = CardKind.from_id(data[0]);
    final values = data.substring(2).split('').map((it) => CardValue.from_id(it)).toList();
    return CardSet(kind, values);
  }

  @override
  bool operator ==(Object other) => toString() == other.toString();

  @override
  int get hashCode => toString().hashCode;

  @override
  String toString() => save();
}

class CardGame {
  CardGame._loaded(this._sets);

  CardGame.default_sets()
      : _sets = {
          CardKind.clubs: CardSet(CardKind.clubs, CardValue.default_set),
          CardKind.diamonds: CardSet(CardKind.diamonds, CardValue.default_set),
          CardKind.hearts: CardSet(CardKind.hearts, CardValue.default_set),
          CardKind.spades: CardSet(CardKind.spades, CardValue.default_set),
        };

  CardGame.full_sets()
      : _sets = {
          CardKind.clubs: CardSet(CardKind.clubs, CardValue.full_set),
          CardKind.diamonds: CardSet(CardKind.diamonds, CardValue.full_set),
          CardKind.hearts: CardSet(CardKind.hearts, CardValue.full_set),
          CardKind.spades: CardSet(CardKind.spades, CardValue.full_set),
        };

  final Map<CardKind, CardSet> _sets;

  Iterable<CardSet> get sets => _sets.values;

  int get number_of_cards_per_set => _sets.values.first.values.length;

  bool are_same_set_ascending_order(Card a, Card b) {
    if (a.kind != b.kind) return false;
    final set = _sets[a.kind];
    if (set == null) throw 'unknown card kind: ${a.kind}';
    final cards = set.cards.toList();
    return cards.indexOf(a) + 1 == cards.indexOf(b);
  }

  bool are_different_color_and_descending_order(Card a, Card b) {
    if (a.kind.color == b.kind.color) return false;
    return _set_index(a) == _set_index(b) + 1;
  }

  int _set_index(Card card) {
    final set = _sets[card.kind];
    if (set == null) throw 'unknown card kind: ${card.kind}';
    return set.cards.toList().indexOf(card);
  }

  GameData save() => {'sets': _sets.values.map((it) => it.save()).toList()};

  static CardGame load(GameData data) =>
      CardGame._loaded((data['sets'] as List).map((it) => CardSet.load(it)).associateBy((it) => it.kind));

  @override
  bool operator ==(Object other) => toString() == other.toString();

  @override
  int get hashCode => toString().hashCode;

  @override
  String toString() => _sets.values.join(',');
}
