import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:flutter/material.dart';

/// Theme-aware score content for completed AniList entries.
/// The star and score use the current accent color without a white outline.
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

  /// Darken the selected theme's card background for contrast.
  static Color get backgroundColor =>
      Color.lerp(appTheme.backgroundSubColor, Colors.black, 0.65)!;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          Icons.star,
          size: starSize,
          color: appTheme.accentColor,
        ),
        Text(
          ' $rating',
          maxLines: 1,
          softWrap: false,
          style: TextStyle(
            fontFamily: 'NotoSans',
            fontSize: textSize,
            fontWeight: weight,
            color: appTheme.accentColor,
          ),
        ),
      ],
    );
  }
}
