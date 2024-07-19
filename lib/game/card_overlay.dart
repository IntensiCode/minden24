import 'dart:ui';

import 'package:flame/components.dart';

import 'cards_selection.dart';

class CardOverlay extends Component {
  CardOverlay({
    required this.size,
    required this.paint,
  }) {
    final rect = Rect.fromPoints(Offset.zero, size.toOffset());
    final radius = Radius.circular(active_card_set.corner_radius);
    this.rect = RRect.fromRectAndRadius(rect, radius);
  }

  final Vector2 size;
  final Paint paint;
  late final RRect rect;

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.drawRRect(rect, paint);
  }
}
