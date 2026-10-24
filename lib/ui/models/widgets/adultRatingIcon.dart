import 'package:flutter/material.dart';
import 'package:animestream/core/app/runtimeDatas.dart';

/// Open-ring 18+ symbol, matching the user-selected design.
class AdultRatingIcon extends StatelessWidget {
  final double size;
  final String? ageRating;
  const AdultRatingIcon({super.key, this.size = 28, this.ageRating});

  @override
  Widget build(BuildContext context) {
    if (currentUserSettings?.showAdultContent != true) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _AdultRingPainter(
          Theme.of(context).colorScheme.onSurface, ageRating)),
    );
  }
}

class _AdultRingPainter extends CustomPainter {
  final Color color;
  final String? ageRating;
  const _AdultRingPainter(this.color, this.ageRating);

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
    // AniList exposes isAdult but no MAL age grade. Use the exact same
    // 18+ ring and upper-right plus as MAL Rx when no grade is provided.
    final grade = (ageRating ?? 'rx').trim().toLowerCase();
    final isR = grade == 'r';
    final isRPlus = grade == 'r+';
    if (isR) {
      canvas.drawCircle(const Offset(27.5, 27.5), 24.5, stroke);
    } else {
      // The '+' occupies the opening at upper right, as in the original icon.
      canvas.drawArc(const Rect.fromLTWH(3, 3, 49, 49),
          -0.90, 5.35, false, stroke);
    }
    final number = TextPainter(
      text: TextSpan(text: isR || isRPlus ? 'R' : '18', style: TextStyle(
          fontSize: 34, fontWeight: FontWeight.w800,
          color: color, height: 1)),
      textDirection: TextDirection.ltr,
    )..layout();
    number.paint(canvas, Offset((55 - number.width) / 2,
        (55 - number.height) / 2 + 2));
    if (!isR) {
      final plus = Paint()..color = color..strokeWidth = 4;
      canvas.drawLine(const Offset(43, 8), const Offset(54, 8), plus);
      canvas.drawLine(const Offset(48.5, 2.5), const Offset(48.5, 13.5), plus);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _AdultRingPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.ageRating != ageRating;
}
