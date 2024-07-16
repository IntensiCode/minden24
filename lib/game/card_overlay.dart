import 'dart:ui';

import 'package:flame/components.dart';

class CardOverlay extends Component {
  CardOverlay({
    required this.size,
    required this.paint,
  }) {
    final rect = Rect.fromPoints(Offset.zero, size.toOffset());
    const radius = Radius.circular(10);
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
