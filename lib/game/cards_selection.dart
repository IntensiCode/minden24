import 'package:flame/components.dart';
import 'package:flame/sprite.dart';

import '../components/basic_menu.dart';
import '../util/auto_dispose.dart';
import '../util/fonts.dart';
import '../util/functions.dart';
import '../util/game_keys.dart';
import '../util/messaging.dart';
import '../util/on_message.dart';
import '../util/storage.dart';
import 'game_dialog.dart';
import 'game_messages.dart';
import 'minden_game.dart';

late CardSet active_card_set;
late SpriteSheet active_cards;

enum CardSet {
  cards(corner_radius: 10),
  cards_clean(corner_radius: 6),
  cards_kin(corner_radius: 2),
  cards_lazy(corner_radius: 3),
  ;

  final double corner_radius;

  const CardSet({required this.corner_radius});
}

class CardsSelection extends Component with AutoDispose {
  static final _dialog_size = Vector2(320, 200);

  late final SpriteSheet _menu_entry;

  @override
  Future onLoad() async {
    super.onLoad();

    priority = 100;

    _menu_entry = await sheetI('button_menu.png', 1, 2);

    final selected = (await load_data('cards_selection')) ?? {};
    final which = selected['cards'] as String? ?? 'cards';
    await _select(which);

    onMessage<PickCards>((it) => pick_cards());
  }

  Future _select(String which) async {
    active_card_set = CardSet.values.firstWhere((it) => it.name == which);
    save_data('cards_selection', {'cards': which});
    active_cards = switch (active_card_set) {
      CardSet.cards => await sheetIWH('$which.png', 72, 92, spacing: 2, margin: 1),
      CardSet.cards_clean => await sheetIWH('$which.png', 128, 178, spacing: 0, margin: 0),
      CardSet.cards_kin => await sheetIWH('$which.png', 39, 54, spacing: 0, margin: 0),
      CardSet.cards_lazy => await sheetIWH('$which.png', 102, 144, spacing: 0, margin: 0),
    };
    sendMessage(RefreshCards());
  }

  Future pick_cards() async {
    if (children.whereType<GameDialog>().isNotEmpty) return;

    GameDialog? dialog;
    await add(dialog = GameDialog(
      size: _dialog_size,
      content: _create_menu(() => dialog?.removeFromParent()),
      keys: DialogKeys(
        handlers: {
          GameKey.soft1: () => dialog?.removeFromParent(),
          GameKey.soft2: () => dialog?.removeFromParent(),
        },
        right: 'Ok',
      ),
    ));
  }

  PositionComponent _create_menu(Hook and_then) => BasicMenu<CardSet>(
        button: _menu_entry,
        font: menu_font,
        fontScale: 0.5,
        fixed_position: _dialog_size / 2,
        fixed_anchor: Anchor.center,
        onSelected: (it) {
          _select(it.name);
          and_then();
        },
      )
        ..addEntry(CardSet.cards, 'Default')
        ..addEntry(CardSet.cards_clean, 'Clean')
        ..addEntry(CardSet.cards_kin, 'KIN\'s')
        ..addEntry(CardSet.cards_lazy, 'Lazyspace')
        ..preselectEntry(active_card_set);
}
