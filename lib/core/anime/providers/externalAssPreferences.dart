import 'package:animestream/core/anime/providers/aniyomiExtensionProvider.dart';
import 'package:animestream/core/anime/providers/types.dart';
import 'package:animestream/ui/models/sources.dart';
import 'package:hive/hive.dart';

/// Opt-in cross-source ASS configuration. Persisted locally, never uploaded.
/// Global: two user-approved sources + language; per show: toggle/last source.
class ExternalAssPreferences {
  static const _box = 'animestream_external_ass_v1';
  static Future<Box> _open() => Hive.openBox(_box);

  static Future<String> primary() async =>
      (await _open()).get('primary', defaultValue: '') as String;
  static Future<String> secondary() async =>
      (await _open()).get('secondary', defaultValue: '') as String;
  static Future<String> language() async =>
      (await _open()).get('language', defaultValue: 'en') as String;
  static Future<void> configure({
    String? primary, String? secondary, String? language,
  }) async {
    final b = await _open();
    if (primary != null) await b.put('primary', primary);
    if (secondary != null) await b.put('secondary', secondary);
    if (language != null) await b.put('language', language);
  }

  static Future<bool> enabled(int animeId) async =>
      (await _open()).get('enabled:$animeId', defaultValue: false) == true;
  static Future<void> setEnabled(int animeId, bool enabled) async =>
      (await _open()).put('enabled:$animeId', enabled);
  static Future<String> lastUsed(int animeId) async =>
      (await _open()).get('last:$animeId', defaultValue: 'primary') as String;
  static Future<void> setLastUsed(int animeId, String source) async {
    if (source != 'primary' && source != 'secondary') return;
    await (await _open()).put('last:$animeId', source);
  }
}

class ExternalAssLookup {
  static String _normalize(String name) =>
      name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();

  static bool _isAss(ExternalSubtitleTrack track) {
    final label = '${track.format} ${track.label} ${track.url}'.toLowerCase();
    return RegExp(r'(ass|ssa)(?:[^a-z]|$)').hasMatch(label);
  }

  static bool _language(ExternalSubtitleTrack track, String wanted) {
    if (wanted == 'any') return true;
    final text = '${track.language} ${track.label}'.toLowerCase();
    const aliases = <String, List<String>>{
      'sv': ['swedish', 'svenska', 'swe', 'sv'],
      'en': ['english', 'eng', 'en'],
      'ja': ['japanese', 'jpn', 'ja'],
      'de': ['german', 'deu', 'ger', 'de'],
      'fr': ['french', 'fra', 'fre', 'fr'],
      'es': ['spanish', 'spa', 'es'],
      'ar': ['arabic', 'ara', 'ar'],
    };
    return (aliases[wanted] ?? [wanted]).any((word) =>
        RegExp('(^|[^a-z])${RegExp.escape(word)}([^a-z]|\$)').hasMatch(text));
  }

  /// Never guess a different series: accept only a unique exact normalized
  /// title result. Episode numbers must be unambiguous and equal.
  static Future<ExternalSubtitleTrack?> find({
    required String sourceId,
    required String title,
    required int episodeNumber,
    required String language,
  }) async {
    if (!AniyomiExtensionProvider.isExtensionId(sourceId) || episodeNumber < 1) {
      return null;
    }
    if (!SourceManager.instance.sources.any((source) => source.identifier == sourceId)) {
      return null;
    }
    final matches = await SourceManager.instance.searchInSource(sourceId, title);
    final exact = matches.where((m) =>
        _normalize(m['name'] ?? '') == _normalize(title) &&
        (m['alias']?.isNotEmpty ?? false)).toList();
    if (exact.length != 1) return null;
    final episodes = await SourceManager.instance.getAnimeEpisodes(
        sourceId, exact.single['alias']!);
    final chosen = episodes.where((e) => e.episodeNumber == episodeNumber).toList();
    if (chosen.length != 1) return null;
    final streams = <VideoStream>[];
    await SourceManager.instance.getStreams(sourceId, chosen.single.episodeLink,
        (batch, _) => streams.addAll(batch), metadata: chosen.single.metadata);
    final tracks = streams.expand((stream) => stream.subtitleTracks)
        .where((track) => _isAss(track) && _language(track, language))
        .toList();
    final urls = tracks.map((t) => t.url).toSet();
    return urls.length == 1 ? tracks.first : null;
  }
}
