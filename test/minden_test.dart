// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minden24/game/card_game.dart';
import 'package:minden24/game/minden_game.dart';
import 'package:minden24/game/minden_settings.dart';

void main() {
  group('comparison', () {
    test('compare card', () {
      final a = Card(kind: CardKind.spades, value: CardValue.ace);
      final b = Card(kind: CardKind.spades, value: CardValue.ace);
      expect(a, equals(b));
    });

    test('compare different card', () {
      final a = Card(kind: CardKind.spades, value: CardValue.ace);
      final b = Card(kind: CardKind.hearts, value: CardValue.ace);
      expect(a, isNot(equals(b)));
    });
  });

  group('save and load', () {
    test('save card', () {
      final it = Card(kind: CardKind.spades, value: CardValue.ace);
      final actual = it.save();
      expect(actual, equals('SA'));
    });

    test('load card', () {
      final actual = Card.load('SA');
      expect(actual, equals(Card(kind: CardKind.spades, value: CardValue.ace)));
    });

    test('save card set', () {
      final it = CardSet(CardKind.spades, [CardValue.ace, CardValue.two]);
      final actual = it.save();
      expect(actual, equals('S:A2'));
    });

    test('load card set', () {
      final actual = CardSet.load('S:A7');
      expect(actual, equals(CardSet(CardKind.spades, [CardValue.ace, CardValue.seven])));
    });

    test('save card game', () {
      final it = CardGame.default_sets();
      final actual = it.save();
      expect(
          actual,
          equals({
            'sets': ['C:A7890JQK', 'D:A7890JQK', 'H:A7890JQK', 'S:A7890JQK']
          }));
    });

    test('load card game', () {
      final actual = CardGame.load({
        'sets': ['C:A7890JQK', 'D:A7890JQK', 'H:A7890JQK', 'S:A7890JQK']
      });
      expect(actual, equals(CardGame.default_sets()));
    });

    test('save card stack', () {
      final it = AceStack()
        ..add_card(Card.load('SA'))
        ..add_card(Card.load('S2'));
      final actual = it.save();
      expect(actual, equals('SA,S2'));
    });

    test('load card stack', () {
      final actual = AceStack()..load('SA,S2');
      expect(
          actual,
          equals(AceStack()
            ..add_card(Card.load('SA'))
            ..add_card(Card.load('S2'))));
    });

    test('save placed card', () {
      final it = PlacedCard(place: Vector2(0, 0), card: Card.load('SA'), is_free_to_move: false);
      final actual = it.save();
      expect(actual, equals('SA[0.0,0.0]'));
    });

    test('load placed card', () {
      final actual = PlacedCard.load('SA[0.5,0.5]');
      expect(actual, equals(PlacedCard(place: Vector2(0.5, 0.5), card: Card.load('SA'), is_free_to_move: false)));
    });

    test('save free placed card', () {
      final it = PlacedCard(place: Vector2(2.5, 0.5), card: Card.load('SA'), is_free_to_move: true);
      final actual = it.save();
      expect(actual, equals('SA[2.5,0.5]f'));
    });

    test('load free placed card', () {
      final actual = PlacedCard.load('SA[0.0,0.0]f');
      expect(actual, equals(PlacedCard(place: Vector2(0, 0), card: Card.load('SA'), is_free_to_move: true)));
    });

    test('save board stack layer', () {
      final it = OddBoardStackLayer(places: 4)..add_card(Card.load('SA'));
      final actual = it.save();
      expect(actual, equals('odd:SA[0.0,0.0]|__|__|__'));
    });

    test('load board stack layer', () {
      final actual = BoardStackLayer.load('odd:SA[0.0,0.0]|__|__|__');
      expect(actual, equals(OddBoardStackLayer(places: 4)..add_card(Card.load('SA'))));
    });

    test('save board stack ', () {
      final it = BoardStack()
        ..add_empty_layer()
        ..add_card(Card.load('SA'));
      final actual = it.save();
      expect(
          actual,
          equals({
            'difficulty': 'hard',
            'layers': ['odd:SA[0.0,0.0]|__|__|__|__|__|__|__|__|__|__|__']
          }));
    });

    test('load board stack ', () {
      final expected = BoardStack()
        ..add_empty_layer()
        ..add_card(Card.load('SA'))
        ..add_empty_layer()
        ..add_card(Card.load('S2'));

      final actual = BoardStack()
        ..load({
          'difficulty': 'hard',
          'layers': ['odd:SA[0.0,0.0]|__|__|__|__|__|__|__|__|__|__|__', 'even:S2[0.5,0.5]|__|__|__|__']
        });
      expect(actual, equals(expected));
    });

    test('save minden game', () {
      final card_game = CardGame.load({
        'sets': ['C:2', 'D:2']
      });
      final settings = MindenSettings(card_game: card_game, difficulty: Difficulty.hard);
      final game = MindenGame();
      game.new_game(new_game_settings: settings);
      final actual = game.save_state();
      expect(
          actual,
          equals({
            'card_game': {
              'sets': ['C:2', 'D:2']
            },
            'board_stack': {
              'difficulty': 'hard',
              'layers': [
                'odd:__|__|__|C2[1.0,1.0]f|D2[2.0,0.0]f|D2[2.0,1.0]f|C2[3.0,0.0]f|C2[3.0,1.0]f|D2[4.0,0.0]f|__|__|__'
              ]
            },
            'ace_stacks': ['', '', '', '', '', '', '', '', '', '', '', ''],
            'play_stacks': ['', '', '', '', '', '', '', '']
          }));
    });
  });

  group('basic card logic', () {
    test('cannot add non-ace to ace stack as first card', () {
      final it = AceStack();
      expect(it.can_add_card(CardGame.default_sets(), Card.load('S2')), isFalse);
    });

    test('can add ace to ace stack as first card', () {
      final it = AceStack();
      expect(it.can_add_card(CardGame.default_sets(), Card.load('SA')), isTrue);
    });

    test('can not add another ace of same kind to ace stack with ace', () {
      final it = AceStack()..add_card(Card.load('SA'));
      expect(it.can_add_card(CardGame.default_sets(), Card.load('SA')), isFalse);
    });

    test('can not add another ace of different kind to ace stack with ace', () {
      final it = AceStack()..add_card(Card.load('SA'));
      expect(it.can_add_card(CardGame.default_sets(), Card.load('DA')), isFalse);
    });

    test('can not add two after ace if default card set game', () {
      final it = AceStack()..add_card(Card.load('SA'));
      expect(it.can_add_card(CardGame.default_sets(), Card.load('S2')), isFalse);
    });

    test('can add two after ace if full card set game', () {
      final it = AceStack()..add_card(Card.load('SA'));
      expect(it.can_add_card(CardGame.full_sets(), Card.load('S2')), isTrue);
    });

    test('can add seven after ace if default card set game', () {
      final it = AceStack()..add_card(Card.load('SA'));
      expect(it.can_add_card(CardGame.default_sets(), Card.load('S7')), isTrue);
    });
  });
}
