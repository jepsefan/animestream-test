import 'package:animestream/core/anime/providers/animeProvider.dart';
import 'package:animestream/core/anime/providers/aniyomiExtensionBridge.dart';
import 'package:animestream/core/anime/providers/types.dart';

/// Wraps an installed Aniyomi APK in AnimeStream's existing provider API.
/// Search, episode loading and playback are performed by the original APK.
class AniyomiExtensionProvider extends AnimeProvider {
  final AniyomiExtensionInfo extension;

  AniyomiExtensionProvider(this.extension);

  static const identifierPrefix = 'aniyomi:';

  static bool isExtensionId(String identifier) =>
      identifier.startsWith(identifierPrefix);

  static String packageFromIdentifier(String identifier) =>
      identifier.substring(identifierPrefix.length);

  @override
  String get providerName => '${extension.name} [Ext]';

  @override
  Future<List<Map<String, String?>>> search(String query) async {
    final result = await AniyomiExtensionBridge.testExtensionSearch(
        extension.packageName, query);
    final status = (result['status'] ?? '').toString();
    if (status != 'search_completed' &&
        status != 'search_completed_unverified') {
      throw StateError('Aniyomi search failed: $status');
    }
    final items = (result['results'] as List?) ?? const [];
    return items.whereType<Map>().map((entry) {
      return <String, String?>{
        'name': entry['title']?.toString(),
        'alias': '${entry['url'] ?? ''}\u001f${entry['title'] ?? ''}',
        'imageUrl': entry['cover']?.toString(),
        'image': entry['cover']?.toString(),
      };
    }).where((item) =>
        (item['name']?.isNotEmpty ?? false) &&
        (item['alias']?.isNotEmpty ?? false)).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getAnimeEpisodeLink(String aliasId,
      {bool dub = false}) async {
    // The title is a required argument on the existing Android bridge.
    // The URL is the actual source identifier; it is never derived from AniList.
    final parts = aliasId.split('\u001f');
    final sourceUrl = parts.first;
    final sourceTitle = parts.length > 1 ? parts.sublist(1).join('\u001f') : sourceUrl;
    final response = await AniyomiExtensionBridge.testExtensionEpisodes(
        extension.packageName, sourceUrl, sourceTitle);
    if (response['status'] != 'episode_list_completed') {
      throw StateError('Aniyomi episodes: ${response['status']}');
    }
    final episodes = (response['episodes'] as List?) ?? const [];
    final result = <Map<String, dynamic>>[];
    for (final item in episodes.whereType<Map>()) {
      final url = item['url']?.toString() ?? '';
      if (url.isEmpty) continue;
      final rawNumber = item['number'];
      final number = rawNumber is num ? rawNumber.toDouble() :
          double.tryParse(rawNumber?.toString() ?? '');
      // Preserve distinct source episode URLs while normalizing the ordinal for UI.
      final ordinal = (number != null && number > 0)
          ? number.round()
          : (episodes.length - result.length);
      result.add({
        'episodeLink': url,
        'episodeNumber': ordinal,
        'episodeTitle': (item['name'] ?? 'Episode $ordinal').toString(),
        'thumbnail': (item['preview']?.toString().isNotEmpty ?? false)
            ? item['preview'].toString() : null,
        'hasDub': dub,
        'metadata': (item['name'] ?? 'Episode $ordinal').toString(),
      });
    }
    // Aniyomi returns newest episodes first; AnimeStream tracks progress oldest first.
    result.sort((a, b) => (a['episodeNumber'] as int)
        .compareTo(b['episodeNumber'] as int));
    return result;
  }

  @override
  Future<void> getStreams(
      String episodeId, void Function(List<VideoStream>, bool) update,
      {bool dub = false, String? metadata}) async {
    final response = await AniyomiExtensionBridge.resolveExtensionStreams(
        extension.packageName, episodeId, metadata ?? 'Episode');
    if (response['status'] != 'stream_list_completed') {
      throw StateError('Aniyomi streams: ${response['status']}');
    }
    final streams = <VideoStream>[];
    for (final item in ((response['videos'] as List?) ?? const []).whereType<Map>()) {
      final url = item['url']?.toString() ?? '';
      if (!(url.startsWith('https://') || url.startsWith('http://'))) continue;
      final rawHeaders = item['headers'];
      final headers = rawHeaders is Map
          ? rawHeaders.map<String, String>(
              (key, value) => MapEntry(key.toString(), value.toString()))
          : <String, String>{};
      final subtitle = item['subtitle']?.toString();
      streams.add(VideoStream(
        quality: item['quality']?.toString() ?? 'Auto',
        url: url,
        server: '${extension.name} [Ext]',
        backup: false,
        subtitle: subtitle?.isNotEmpty == true ? subtitle : null,
        subtitleFormat: (item['subtitleFormat'] ?? '').toString(),
        customHeaders: headers,
      ));
    }
    if (streams.isEmpty) throw StateError('Aniyomi: no playable streams returned');
    update(streams, true);
  }

  @override
  Future<void> getDownloadSources(
      String episodeUrl, void Function(List<VideoStream>, bool) update,
      {bool dub = false, String? metadata}) async {
    throw UnimplementedError('Aniyomi extension downloads are not enabled');
  }
}
