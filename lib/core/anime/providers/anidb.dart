import 'package:animestream/core/anime/providers/animeProvider.dart';
import 'package:animestream/core/anime/providers/types.dart';
import 'package:animestream/core/network/network.dart';
import 'package:html/parser.dart' as html;

/// HTML-based AniDB.se provider. No dependency on the retired anidb.app API.
class AniDB implements AnimeProvider {
  final int variant;
  AniDB({this.variant = 3});
  @override
  String get providerName => 'AniDB V$variant';

  static const _baseUrl = 'https://anidb.se';
  static const _headers = {'User-Agent': 'Mozilla/5.0'};
  static final _episodePattern = RegExp(
    r'-episode-(\d+)-english-subbed/?$', caseSensitive: false);
  static final _numberPattern = RegExp(
    r'(?:episode|ep)\s*#?\s*(\d+)', caseSensitive: false);

  Uri _uri(String path) => Uri.parse(_baseUrl).resolve(path);

  String _slug(String alias) {
    final uri = Uri.tryParse(alias);
    final segments = (uri?.path ?? alias).split('/').where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty) throw FormatException('Missing AniDB anime slug');
    return segments.last;
  }

  String _episodeUrl(String slug, int number) =>
      '$_baseUrl/$slug-episode-$number-english-subbed/';

  Future<String> _page(Uri uri) async {
    final response = await get(uri,
        headers: _headers, cacheDuration: const Duration(minutes: 5));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('AniDB HTTP ${response.statusCode}: $uri');
    }
    return response.body;
  }

  @override
  Future<List<Map<String, String?>>> search(String query) async {
    final document = html.parse(await _page(
        _uri('/?s=${Uri.encodeQueryComponent(query)}')));
    final results = <Map<String, String?>>[];
    final seen = <String>{};
    for (final a in document.querySelectorAll('a[href]')) {
      final href = a.attributes['href'];
      if (href == null) continue;
      final url = _uri(href);
      if (url.host != Uri.parse(_baseUrl).host ||
          !url.path.startsWith('/anime/')) continue;
      final slug = _slug(url.toString());
      if (!seen.add(slug)) continue;
      final image = a.querySelector('img');
      final title = a.attributes['title'] ?? image?.attributes['alt'] ??
          a.text.trim();
      if (title.isEmpty) continue;
      final src = image?.attributes['src'];
      results.add({
        'name': title,
        'alias': url.toString(),
        'imageUrl': src == null ? null : url.resolve(src).toString(),
      });
    }
    return results;
  }

  @override
  Future<List<Map<String, dynamic>>> getAnimeEpisodeLink(String aliasId,
      {bool dub = false}) async {
    final slug = _slug(aliasId);
    final seriesUrl = _uri('/anime/$slug/');
    final document = html.parse(await _page(seriesUrl));
    final candidates = <int, String>{};
    for (final a in document.querySelectorAll('a')) {
      final href = a.attributes['href'] ?? '';
      final absolute = seriesUrl.resolve(href);
      final match = _episodePattern.firstMatch(absolute.path);
      final textMatch = _numberPattern.firstMatch(a.text);
      final number = match == null
          ? int.tryParse(textMatch?.group(1) ?? '')
          : int.tryParse(match.group(1)!);
      if (number == null || number < 1) continue;
      final validLink = variant != 1 && href.isNotEmpty && href != '#' &&
          absolute.host == seriesUrl.host && match != null;
      candidates[number] = validLink
          ? absolute.toString() : _episodeUrl(slug, number);
    }
    if (candidates.isEmpty) {
      throw Exception('AniDB series page contains no recognizable episode numbers');
    }
    final episodes = <Map<String, dynamic>>[];
    for (final number in candidates.keys.toList()..sort()) {
      final url = candidates[number]!;
      try {
        final page = html.parse(await _page(Uri.parse(url)));
        print('[AniDB V$variant] Checking episode $number: $url');
        // A successful HTTP response alone is not proof of publication.
        final canonical = page.querySelector('link[rel="canonical"]')
            ?.attributes['href'];
        if (variant != 1 && canonical != null &&
            Uri.parse(url).resolve(canonical).path != Uri.parse(url).path) {
          continue;
        }
        final hasEpisode = page.querySelector('iframe[src], video[src], video source[src], [data-src], [data-video]') != null ||
            page.querySelectorAll('script').any((s) =>
                RegExp(r'm3u8|mp4|embed|sources?\s*:', caseSensitive: false)
                    .hasMatch(s.text));
        if (variant != 1 && !hasEpisode) continue;
        episodes.add({
          'episodeLink': url,
          'episodeNumber': number.toString(),
          'episodeTitle': null,
          'thumbnail': null,
          'hasDub': false,
          'isFiller': false,
        });
      } catch (_) {
        // Network failures are not evidence of an unpublished episode.
        // Propagate instead of silently hiding potentially valid episodes.
        rethrow;
      }
    }
    return episodes;
  }

  @override
  Future<void> getStreams(String episodeId,
      Function(List<VideoStream>, bool) update,
      {bool dub = false, String? metadata}) async {
    final pageUrl = Uri.parse(episodeId);
    final document = html.parse(await _page(pageUrl));
    final urls = <String>{};
    for (final element in document.querySelectorAll('video[src], video source[src]')) {
      final src = element.attributes['src'];
      if (src != null) urls.add(pageUrl.resolve(src).toString());
    }
    final direct = RegExp(
        r'''https?:[^\s"'<>]+\.(?:m3u8|mp4)(?:\?[^\s"'<>]*)?''',
        caseSensitive: false);
    for (final match in direct.allMatches(document.outerHtml.replaceAll(r'\/', '/'))) {
      urls.add(match.group(0)!);
    }
    for (final url in urls) {
      update([
        VideoStream(url: url, quality: 'default', server: 'Anidb',
            backup: false, customHeaders: {'referer': episodeId})
      ], false);
    }
    // Embed-only players need a site-specific resolver; do not pretend
    // that an iframe URL is a playable media URL.
    update([], true);
  }

  @override
  Future<void> getDownloadSources(String episodeUrl,
      Function(List<VideoStream>, bool) update,
      {bool dub = false, String? metadata}) async {
    throw UnimplementedError();
  }
}

class AniDBV1 extends AniDB { AniDBV1() : super(variant: 1); }
class AniDBV2 extends AniDB { AniDBV2() : super(variant: 2); }
class AniDBV3 extends AniDB { AniDBV3() : super(variant: 3); }
