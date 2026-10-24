/// AniZone lists regular episodes and specials together. Its /sN links are
/// *special indices*, not canonical TV episode numbers.
class AniZoneEpisodeIdentity {
  final int number;
  final String label;
  final bool moveBeforeRegularEpisodes;

  const AniZoneEpisodeIdentity({
    required this.number,
    required this.label,
    this.moveBeforeRegularEpisodes = false,
  });

  static bool isSpecial(String link, String? type) {
    final kind = (type ?? '').toLowerCase();
    final path = Uri.tryParse(link)?.path ?? '';
    return kind.contains('special') ||
        RegExp(r'/s[0-9]+/?$', caseSensitive: false).hasMatch(path);
  }

  static AniZoneEpisodeIdentity fromSource({
    required String animeUrl,
    required String episodeUrl,
    required String? title,
    required String? type,
    required int regularIndex,
    required int specialIndex,
  }) {
    if (!isSpecial(episodeUrl, type)) {
      // AniZone labels /1, /2, etc. for regular episodes. Never count
      // specials in this ordinal, regardless of their location in the list.
      final path = Uri.tryParse(episodeUrl)?.path ?? '';
      final match = RegExp(r'/([0-9]+)/?$').firstMatch(path);
      final sourceNumber = match == null ? null : int.tryParse(match.group(1)!);
      final number = (sourceNumber != null && sourceNumber > 0)
          ? sourceNumber
          : regularIndex;
      return AniZoneEpisodeIdentity(number: number, label: 'Episode $number');
    }

    // AniZone indexes this episode as special s1, but the verified season
    // chronology identifies it as season 2, episode 0 (aired before ep. 1).
    // Don't infer that all s1 specials are ep. 0: many are post-season OVAs.
    final animePath = Uri.tryParse(animeUrl)?.path ?? '';
    final epPath = Uri.tryParse(episodeUrl)?.path ?? '';
    final guardianFitz = animePath.endsWith('/anime/5vkncg7n') &&
        epPath.endsWith('/s1') &&
        (title ?? '').trim().toLowerCase() == 'guardian fitz';
    if (guardianFitz) {
      return const AniZoneEpisodeIdentity(
        number: 0,
        label: 'Episode 0',
        moveBeforeRegularEpisodes: true,
      );
    }

    return AniZoneEpisodeIdentity(
      number: 0,
      label: 'Special $specialIndex',
    );
  }
}
