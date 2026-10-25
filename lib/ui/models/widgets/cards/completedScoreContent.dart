import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:flutter/material.dart';

/// Theme-aware score glyphs for series completed in the user's AniList list.
/// The white edge is painted around the star and individual digits, not the
/// badge container, so the score stays readable over the darker theme color.
class CompletedScoreContent extends StatelessWidget {
  final String rating;
  final double starSize;
  final double textSize;
  final FontWeight weight;

  const CompletedScoreContent({
    super.key,
    required this.rating,
    this.starSize = 13,
    this.textSize = 14,
    this.weight = FontWeight.bold,
  });

  /// Use the selected theme's card background, darkened for contrast in both
  /// dark and light themes. Never substitute a fixed brand/accent color.
  static Color get backgroundColor =>
      Color.lerp(appTheme.backgroundSubColor, Colors.black, 0.65)!;

  Widget _outlinedGlyph(String value, TextStyle baseStyle) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Text(
          value,
          maxLines: 1,
          softWrap: false,
          style: baseStyle.copyWith(
            foreground: Paint()
              ..color = Colors.white
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2
              ..strokeJoin = StrokeJoin.round,
          ),
        ),
        Text(
          value,
          maxLines: 1,
          softWrap: false,
          style: baseStyle.copyWith(color: appTheme.accentColor),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _outlinedGlyph(
          String.fromCharCode(Icons.star.codePoint),
          TextStyle(
            fontFamily: Icons.star.fontFamily,
            fontSize: starSize,
            height: 1,
          ),
        ),
        _outlinedGlyph(
          ' $rating',
          TextStyle(
            fontFamily: 'NotoSans',
            fontSize: textSize,
            fontWeight: weight,
          ),
        ),
      ],
    );
  }
}
