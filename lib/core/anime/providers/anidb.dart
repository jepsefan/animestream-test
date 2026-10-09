import 'package:animestream/core/anime/providers/animeProvider.dart';
import 'package:animestream/core/anime/providers/types.dart';
import 'package:animestream/core/network/network.dart';
import 'package:html/parser.dart' as html;
import 'dart:convert';

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
        // Player markup may be injected after page load; keep valid episode links.
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

  // V1: direct media URLs. V2: attributes + embeds.
  // V3: V2 + Base64 inline JS; UVP config is not a media URL.
  static final _media = RegExp(
      r'''https?://[^\s"'<>\\]+?\.(?:mp4|m3u8|mpd|webm)(?:\?[^\s"'<>\\]*)?''',
      caseSensitive: false);

  void _scan(String input, Uri base, Set<String> urls) {
    final text = input.replaceAll(r'\/', '/').replaceAll(r'\u0026', '&');
    for (final m in _media.allMatches(text)) {
      final uri = Uri.tryParse(m.group(0)!);
      if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
        urls.add(uri.toString());
      }
    }
  }

  Future<void> _resolve(Uri page, Set<String> urls, Set<String> visited,
      int depth) async {
    if (depth > 2 || !visited.add(page.toString())) return;
    final markup = await _page(page);
    if (variant == 1) {
      _scan(markup, page, urls);
      return;
    }
    final doc = html.parse(markup);
    for (final el in doc.querySelectorAll(
        'video, source, [data-src], [data-video], [data-file], [data-hls]')) {
      for (final key in const [
        'src', 'data-src', 'data-video', 'data-file', 'data-hls'
      ]) {
        final value = el.attributes[key];
        if (value == null) continue;
        final uri = page.resolve(value.startsWith('//')
            ? page.scheme + ':' + value : value);
        if (RegExp(r'\.(mp4|m3u8|mpd|webm)(\?|$)', caseSensitive: false)
            .hasMatch(uri.toString()) &&
            (uri.scheme == 'http' || uri.scheme == 'https')) {
          urls.add(uri.toString());
        }
      }
    }
    for (final script in doc.querySelectorAll('script')) {
      _scan(script.text, page, urls);
      if (variant == 3) {
        final src = script.attributes['src'] ?? '';
        const prefix = 'data:text/javascript;base64,';
        if (src.startsWith(prefix)) {
          try {
            _scan(utf8.decode(base64.decode(src.substring(prefix.length))),
                page, urls);
          } catch (_) {
            print('[AniDB V3] Invalid Base64 script');
          }
        }
      }
    }
    if (variant == 3) {
      print('[AniDB V3] UVP=' + markup.contains('uvp-player-js').toString() +
          ' media=' + urls.length.toString());
    }
    for (final el in doc.querySelectorAll('iframe[src], iframe[data-src]')) {
      final src = el.attributes['src'] ?? el.attributes['data-src'];
      if (src == null) continue;
      final uri = page.resolve(src);
      if (uri.scheme != 'https' && uri.scheme != 'http') continue;
      try {
        await _resolve(uri, urls, visited, depth + 1);
      } catch (e) {
        print('[AniDB V' + variant.toString() + '] Embed error: ' + e.toString());
      }
    }
  }

  @override
  Future<void> getStreams(String episodeId,
      Function(List<VideoStream>, bool) update,
      {bool dub = false, String? metadata}) async {
    final urls = <String>{};
    try {
      await _resolve(Uri.parse(episodeId), urls, <String>{}, 0);
      print('[AniDB V' + variant.toString() +
          '] stream candidates=' + urls.length.toString());
      update(urls.map((url) => VideoStream(
        url: url, quality: 'default', server: 'AniDB V' + variant.toString(),
        backup: false, customHeaders: {'referer': episodeId},
      )).toList(), true);
    } catch (e) {
      print('[AniDB V' + variant.toString() + '] Stream error: ' + e.toString());
      update([], true);
      rethrow;
    }
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
