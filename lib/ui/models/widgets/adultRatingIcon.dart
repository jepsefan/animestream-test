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
          Theme.of(context).colorScheme.onSurface, ageRating,
          size <= 32)),
    );
  }
}

class _AdultRingPainter extends CustomPainter {
  final Color color;
  final String? ageRating;
  final bool outlined;
  const _AdultRingPainter(this.color, this.ageRating, this.outlined);

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 55;
    canvas.save();
    canvas.scale(scale);
    // Draw small-cover badges with a dark edge so the light rating and '+'
    // remain readable even on bright, detailed artwork.
    final ring = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.4
      ..strokeCap = StrokeCap.square;
    final ringOutline = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.8
      ..strokeCap = StrokeCap.square;

    // AniList lacks MAL grading and shares MAL Rx's 18+ graphic.
    final grade = (ageRating ?? 'rx').trim().toLowerCase();
    final isR = grade == 'r';
    final isRPlus = grade == 'r+';
    final glyph = isR || isRPlus ? 'R' : '18';

    void drawRing(Paint paint) {
      if (isR) {
        canvas.drawCircle(const Offset(27.5, 27.5), 24.5, paint);
      } else {
        // Preserve the upper/left endpoint (5.03 rad). Only move the
        // LOWER endpoint clockwise so it clears the bottom of '+'.
        // Previous: start -0.55, sweep 5.58 (end 5.03).
        canvas.drawArc(const Rect.fromLTWH(3, 3, 49, 49),
            -0.27, 5.30, false, paint);
      }
    }

    if (outlined) drawRing(ringOutline);
    drawRing(ring);

    final textStyle = TextStyle(
      fontSize: 34, fontWeight: FontWeight.w800, color: color, height: 1);
    final number = TextPainter(
      text: TextSpan(text: glyph, style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    final textOffset = Offset((55 - number.width) / 2,
        (55 - number.height) / 2 + 2);
    if (outlined) {
      final outlineNumber = TextPainter(
        text: TextSpan(text: glyph, style: TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w800,
          height: 1,
          foreground: Paint()
            ..color = Colors.black
            ..style = PaintingStyle.stroke
            ..strokeJoin = StrokeJoin.round
            ..strokeWidth = 2.8,
        )),
        textDirection: TextDirection.ltr,
      )..layout();
      outlineNumber.paint(canvas, textOffset);
    }
    number.paint(canvas, textOffset);

    if (!isR) {
      void drawPlus(Paint paint) {
        canvas.drawLine(const Offset(41.5, 9), const Offset(50.5, 9), paint);
        canvas.drawLine(const Offset(46, 4.5), const Offset(46, 13.5), paint);
      }
      if (outlined) {
        drawPlus(Paint()
          ..color = Colors.black
          ..strokeWidth = 6.4
          ..strokeCap = StrokeCap.square);
      }
      drawPlus(Paint()
        ..color = color
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.square);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _AdultRingPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.ageRating != ageRating ||
      oldDelegate.outlined != outlined;
}
