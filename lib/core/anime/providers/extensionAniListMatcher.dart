import 'dart:convert';

import 'package:animestream/core/commons/enums.dart';
import 'package:animestream/core/database/anilist/anilist.dart';

/// AniList remains the primary identity and artwork source. Extension
/// title/URL only identify an explicitly selected playback source.
class ExtensionAniListMatcher {
  static String normalize(String value) => value.toLowerCase()
      .replaceAll(RegExp(r'[^\\p{L}\\p{N}]+', unicode: true), ' ')
      .trim()
      .replaceAll(RegExp(r'\\s+'), ' ');

  static String baseTitle(String value) => normalize(value)
      .replaceAll(RegExp(r'\\b(?:season|part|cour)\\s*\\d+\\b'), '')
      .replaceAll(RegExp(r'\\b(?:[2-9](?:nd|rd|th) season|dub|sub|ova|recap)\\b'), '')
      .trim();

  static int score(String source, List<String> aliases) {
    final name = normalize(source);
    final base = baseTitle(source);
    if (name.isEmpty) return 0;
    var best = 0;
    for (final alias in aliases) {
      final candidate = normalize(alias);
      if (candidate.isEmpty) continue;
      if (candidate == name) return 100;
      if (base.isNotEmpty && base == baseTitle(alias)) best = best < 85 ? 85 : best;
      if (candidate.contains(name) || name.contains(candidate)) {
        if (best < 70) best = 70;
      }
      final sourceWords = base.split(' ').where((e) => e.length > 2).toSet();
      final aliasWords = baseTitle(alias).split(' ').where((e) => e.length > 2).toSet();
      if (sourceWords.isNotEmpty && aliasWords.isNotEmpty) {
        final overlap = sourceWords.intersection(aliasWords).length;
        final ratio = overlap / sourceWords.union(aliasWords).length;
        final points = (ratio * 65).round();
        if (points > best) best = points;
      }
    }
    return best;
  }

  static Future<List<Map<String, dynamic>>> rank(
      String query, List<dynamic> results) async {
    // Escape GraphQL input as a quoted JSON string, rather than interpolating
    // untrusted text directly into GraphQL syntax.
    final escaped = jsonEncode(query);
    final gql = '''
      query {
        Page(perPage: 25) {
          media(search: $escaped, type: ANIME, isAdult: false) {
            id
            title { english romaji native }
            synonyms
            coverImage { large }
          }
        }
      }
    ''';
    final raw = await Anilist().fetchQuery(
      gql, RequestType.media, cacheDuration: const Duration(minutes: 10));
    final media = (raw as List?) ?? const [];
    final candidates = media.whereType<Map>().map((entry) {
      final title = entry['title'] as Map? ?? {};
      final aliases = [
        for (final key in ['english', 'romaji', 'native'])
          if (title[key] is String) title[key] as String,
        ...((entry['synonyms'] as List?) ?? const []).whereType<String>(),
      ];
      return {
        'id': entry['id'],
        'aliases': aliases,
        'cover': entry['coverImage'] is Map
            ? (entry['coverImage'] as Map)['large'] : null,
        'english': title['english'],
        'romaji': title['romaji'],
      };
    }).toList();
    return results.whereType<Map>().map((entry) {
      final name = (entry['title'] ?? '').toString();
      final ranked = candidates.map((candidate) => {
        ...candidate,
        'score': score(name, List<String>.from(candidate['aliases'] as List)),
      }).toList()..sort((a,b) => (b['score'] as int).compareTo(a['score'] as int));
      final best = ranked.isEmpty ? null : ranked.first;
      final confidence = best == null ? 0 : best['score'] as int;
      return <String, dynamic>{
        'title': name,
        'url': (entry['url'] ?? '').toString(),
        'sourceCover': (entry['cover'] ?? '').toString(),
        'anilistId': confidence >= 70 ? best?['id'] : null,
        'anilistTitle': confidence >= 70
            ? (best?['english'] ?? best?['romaji']) : null,
        'anilistCover': confidence >= 70 ? best?['cover'] : null,
        'score': confidence,
        'matchStatus': confidence >= 90 ? 'strong' :
            confidence >= 70 ? 'possible' : 'manual_selection_required',
      };
    }).toList()
      ..sort((a,b) => (b['score'] as int).compareTo(a['score'] as int));
  }
}
