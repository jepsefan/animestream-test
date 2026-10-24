import 'package:flutter/material.dart';
import 'package:animestream/core/app/runtimeDatas.dart';

/// Open-ring 18+ symbol, matching the user-selected design.
class AdultRatingIcon extends StatelessWidget {
  final double size;
  const AdultRatingIcon({super.key, this.size = 28});

  @override
  Widget build(BuildContext context) {
    if (currentUserSettings?.showAdultContent != true) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _AdultRingPainter(
          Theme.of(context).colorScheme.onSurface)),
    );
  }
}

class _AdultRingPainter extends CustomPainter {
  final Color color;
  const _AdultRingPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 55;
    canvas.save();
    canvas.scale(scale);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.4
      ..strokeCap = StrokeCap.square;
    // Open the circle at the upper-right where the plus sign sits.
    canvas.drawArc(const Rect.fromLTWH(3, 3, 49, 49),
        -0.90, 5.35, false, stroke);
    final number = TextPainter(
      text: TextSpan(text: '18', style: TextStyle(
          fontSize: 34, fontWeight: FontWeight.w800,
          color: color, height: 1)),
      textDirection: TextDirection.ltr,
    )..layout();
    number.paint(canvas, Offset((55 - number.width) / 2,
        (55 - number.height) / 2 + 2));
    final plus = Paint()..color = color..strokeWidth = 4;
    canvas.drawLine(const Offset(43, 8), const Offset(54, 8), plus);
    canvas.drawLine(const Offset(48.5, 2.5), const Offset(48.5, 13.5), plus);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _AdultRingPainter oldDelegate) =>
      oldDelegate.color != color;
}
