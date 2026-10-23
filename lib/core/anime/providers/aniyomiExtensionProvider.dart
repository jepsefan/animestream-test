import 'package:animestream/core/anime/providers/animeProvider.dart';
import 'package:animestream/core/anime/providers/aniyomiExtensionBridge.dart';
import 'package:animestream/core/anime/providers/types.dart';
import 'package:animestream/core/anime/providers/extensionEpisodeNumber.dart';

/// Wraps an installed Aniyomi APK in AnimeStream's existing provider API.
/// Search, episode loading and playback are performed by the original APK.
class AniyomiExtensionProvider extends AnimeProvider {
  final AniyomiExtensionInfo extension;

  final AniyomiExtensionSourceInfo? selectedSource;

  AniyomiExtensionProvider(this.extension, {this.selectedSource});

  static const identifierPrefix = 'aniyomi:';

  static String identifier(String packageName, int sourceId) =>
      '$identifierPrefix$packageName#$sourceId';

  static bool isExtensionId(String identifier) =>
      identifier.startsWith(identifierPrefix);

  static String packageFromIdentifier(String identifier) =>
      identifier.substring(identifierPrefix.length);

  @override
  String get providerName => '${selectedSource?.name ?? extension.name} [Ext]';

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
          extension.packageName, variant,
          sourceId: selectedSource?.id,
          sourceName: selectedSource?.name,
          sourceLanguage: selectedSource?.language);
      final status = (response['status'] ?? '').toString();
      if (status != 'search_completed' &&
          status != 'search_completed_unverified') {
        throw StateError('Aniyomi search failed: $status');
      }
      // A successful HTTP response can be an unrelated browse page.
      if (response['resultRelevance'] == 'unverified_unrelated_catalogue') continue;
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
    final response = await AniyomiExtensionBridge.loadExtensionEpisodes(
        extension.packageName, sourceUrl, sourceTitle,
        sourceId: selectedSource?.id,
        sourceName: selectedSource?.name,
        sourceLanguage: selectedSource?.language);
    if (response['status'] != 'episode_list_completed') {
      throw StateError('Aniyomi episodes: ${response['status']}');
    }
    final episodes = (response['episodes'] as List?) ?? const [];
    final result = <Map<String, dynamic>>[];
    for (final item in episodes.whereType<Map>()) {
      final url = item['url']?.toString() ?? '';
      if (url.isEmpty) continue;
      final episodeName = (item['name'] ?? '').toString();
      final parsed = ExtensionEpisodeNumber.parse(item['number'], episodeName);
      // The native host resolves relative preview URLs against the selected
      // extension domain. Reject unsupported schemes before displaying them.
      final preview = item['preview']?.toString().trim() ?? '';
      final previewUri = Uri.tryParse(preview);
      final thumbnail = previewUri != null &&
              previewUri.hasAuthority &&
              (previewUri.scheme == 'https' || previewUri.scheme == 'http')
          ? previewUri.toString()
          : null;
      result.add({
        'episodeLink': url,
        'episodeNumber': parsed.number,
        'episodeLabel': parsed.label,
        'episodeTitle': episodeName.isEmpty ? parsed.label : episodeName,
        'thumbnail': thumbnail,
        'hasDub': dub,
        'metadata': episodeName.isEmpty ? parsed.label : episodeName,
      });
    }
    // Many extensions return newest first; AnimeStream tracks oldest first.
    // Keep the source order for specials/unnumbered episodes. Sort only
    // consecutive runs of numbered episodes (stable on equal numbers), so
    // unknown positions cannot be promoted to made-up episode identities.
    final known = result.where((entry) =>
        (entry['episodeNumber'] as int) > 0).toList();
    if (known.length >= 2 &&
        (known.first['episodeNumber'] as int) >
            (known.last['episodeNumber'] as int)) {
      result.setAll(0, result.reversed.toList());
    }
    var start = 0;
    while (start < result.length) {
      if ((result[start]['episodeNumber'] as int) <= 0) {
        start++;
        continue;
      }
      var end = start + 1;
      while (end < result.length &&
          (result[end]['episodeNumber'] as int) > 0) {
        end++;
      }
      final group = result.sublist(start, end).asMap().entries.toList()
        ..sort((a, b) {
          final compare = (a.value['episodeNumber'] as int)
              .compareTo(b.value['episodeNumber'] as int);
          return compare != 0 ? compare : a.key.compareTo(b.key);
        });
      result.setRange(start, end, group.map((entry) => entry.value));
      start = end;
    }
    return result;
  }

  @override
  Future<void> getStreams(
      String episodeId, void Function(List<VideoStream>, bool) update,
      {bool dub = false, String? metadata}) async {
    final response = await AniyomiExtensionBridge.resolveExtensionStreams(
        extension.packageName, episodeId, metadata ?? 'Episode',
        sourceId: selectedSource?.id,
        sourceName: selectedSource?.name,
        sourceLanguage: selectedSource?.language);
    if (response['status'] != 'stream_list_completed') {
      final safeError = response['error']?.toString() ?? '';
      final diagnosis = response['diagnosis']?.toString() ?? '';
      throw StateError('Aniyomi streams: ${response['status']}'
          '${safeError.isEmpty ? '' : ' ($safeError)'}'
          '${diagnosis.isEmpty ? '' : ' [$diagnosis]'}');
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
      final audioTracks = ((item['audioTracks'] as List?) ?? const [])
          .whereType<Map>()
          .map((track) => ExternalAudioTrack.fromMap(track))
          .where((track) => track.url.startsWith('https://') ||
              track.url.startsWith('http://'))
          .toList();
      final rawHoster = (item['hosterName'] ?? '').toString().trim();
      // Some legacy/multisrc sources report a synthetic Hoster called
      // "no_hoster_list". That is not a real server name.
      final usefulHoster = rawHoster.isNotEmpty &&
          !const {'no_hoster_list', 'none', 'unknown'}
              .contains(rawHoster.toLowerCase().replaceAll(' ', '_'));
      final qualityLabel = (item['quality'] ?? '').toString();
      // Older extensions commonly return server names inside a structured
      // quality string: "SUB - Omega - VidMoly - 720p". Use only an explicit
      // multi-part format; do not guess a host from a video URL.
      final parts = qualityLabel.split(RegExp(r'\s+-\s+'))
          .map((part) => part.trim()).where((part) => part.isNotEmpty).toList();
      final inferred = !usefulHoster &&
              parts.length >= 4 &&
              RegExp(r'^\d{3,4}p?(?:\s*\(.*\))?$', caseSensitive: false)
                  .hasMatch(parts.last)
          ? parts[parts.length - 2]
          : '';
      final hosterName = usefulHoster ? rawHoster : inferred;
      streams.add(VideoStream(
        quality: item['quality']?.toString() ?? 'Auto',
        url: url,
        server: hosterName.isNotEmpty
            ? '$providerName • $hosterName'
            : providerName,
        backup: false,
        subtitle: subtitle?.isNotEmpty == true ? subtitle : null,
        subtitleTracks: subtitles,
        externalAudioTracks: audioTracks,
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
