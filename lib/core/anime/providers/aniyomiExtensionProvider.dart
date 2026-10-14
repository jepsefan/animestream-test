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
    final cleanQuery = query.trim();
    final suffix = RegExp(
      r'\s*(?:[-:–]\s*)?(?:season|part|cour)\s*\d+\s*' + r'$',
      caseSensitive: false,
    );
    final baseQuery = cleanQuery.replaceAll(suffix, '').trim();
    final plainQuery = baseQuery
        .replaceAll(RegExp(r'[^\p{L}\p{N}\s]+', unicode: true), ' ')
        .replaceAll(RegExp(r'\s+'), ' ').trim();
    final variants = <String>{cleanQuery, baseQuery, plainQuery}
        .where((variant) => variant.isNotEmpty).toList();
    for (final variant in variants) {
      final response = await AniyomiExtensionBridge.testExtensionSearch(
          extension.packageName, variant);
      final status = (response['status'] ?? '').toString();
      if (status != 'search_completed' &&
          status != 'search_completed_unverified') {
        throw StateError('Aniyomi search failed: $status');
      }
      // A successful HTTP response can be an unrelated browse page.
      if (response['relevance'] == 'unverified_unrelated_catalogue') continue;
      final items = (response['results'] as List?) ?? const [];
      final parsed = items.whereType<Map>().where((item) =>
          (item['url']?.toString().isNotEmpty ?? false) &&
          (item['title']?.toString().isNotEmpty ?? false)).map((item) {
        return <String, String?>{
          'name': item['title']?.toString(),
          'alias': '${item['url'] ?? ''}\u001f${item['title'] ?? ''}',
          'imageUrl': item['cover']?.toString(),
          'image': item['cover']?.toString(),
        };
      }).where((item) =>
          (item['name']?.isNotEmpty ?? false) &&
          (item['alias']?.isNotEmpty ?? false)).toList();
      if (parsed.isNotEmpty) return parsed;
    }
    return <Map<String, String?>>[];
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
    // Many extensions return newest first; AnimeStream tracks oldest first.
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
      // Only expose status/diagnostic enum values from the native bridge.
      // No URL, access token, HTTP header or cookie enters the UI/logs.
      final status = (response['status'] ?? 'stream_list_failed').toString();
      final diagnosis = (response['diagnosis'] ?? 'unavailable').toString();
      throw AniyomiStreamResolutionException(
        RegExp(r'^[a-z_]+
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
      final rawTracks = item['subtitleTracks'] as List? ?? const [];
      final subtitles = rawTracks.whereType<Map>().map(
          (entry) => ExternalSubtitleTrack.fromMap(entry)).where(
          (track) => track.url.startsWith('https://') ||
              track.url.startsWith('http://')).toList();
      streams.add(VideoStream(
        quality: item['quality']?.toString() ?? 'Auto',
        url: url,
        server: '${extension.name} [Ext]',
        backup: false,
        subtitle: subtitle?.isNotEmpty == true ? subtitle : null,
        subtitleTracks: subtitles,
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
).hasMatch(status) ? status : 'stream_list_failed',
        RegExp(r'^[a-z_]+
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
      final rawTracks = item['subtitleTracks'] as List? ?? const [];
      final subtitles = rawTracks.whereType<Map>().map(
          (entry) => ExternalSubtitleTrack.fromMap(entry)).where(
          (track) => track.url.startsWith('https://') ||
              track.url.startsWith('http://')).toList();
      streams.add(VideoStream(
        quality: item['quality']?.toString() ?? 'Auto',
        url: url,
        server: '${extension.name} [Ext]',
        backup: false,
        subtitle: subtitle?.isNotEmpty == true ? subtitle : null,
        subtitleTracks: subtitles,
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
).hasMatch(diagnosis) ? diagnosis : 'unavailable',
      );
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
      final rawTracks = item['subtitleTracks'] as List? ?? const [];
      final subtitles = rawTracks.whereType<Map>().map(
          (entry) => ExternalSubtitleTrack.fromMap(entry)).where(
          (track) => track.url.startsWith('https://') ||
              track.url.startsWith('http://')).toList();
      streams.add(VideoStream(
        quality: item['quality']?.toString() ?? 'Auto',
        url: url,
        server: '${extension.name} [Ext]',
        backup: false,
        subtitle: subtitle?.isNotEmpty == true ? subtitle : null,
        subtitleTracks: subtitles,
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

/// Safe classification for external source errors. Never store signed media
/// URLs, access tokens, auth headers or exception causes here.
class AniyomiStreamResolutionException implements Exception {
  final String status;
  final String diagnosis;
  const AniyomiStreamResolutionException(this.status, this.diagnosis);

  @override
  String toString() => 'Aniyomi stream unavailable: $status ($diagnosis)';
}
