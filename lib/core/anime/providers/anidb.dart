import 'package:animestream/core/anime/providers/animeProvider.dart';
import 'package:animestream/core/anime/providers/types.dart';
import 'package:animestream/core/network/network.dart';
import 'package:html/parser.dart' as html;
import 'dart:convert';
import 'package:http/http.dart' as http;

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
    print('[AniDB V$variant] PAGE status=${response.statusCode} type=${response.headers['content-type']} path=${uri.path}');
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
    // Do not treat sidebar 'Ongoing Animes' episode links as this series.
    // Match the exact series slug, not merely an episode number.
    final ownEpisode = RegExp(
      '^/' + RegExp.escape(slug) + r'-episode-(\d+)-english-subbed/?$',
      caseSensitive: false,
    );
    for (final a in document.querySelectorAll('a[href]')) {
      final href = a.attributes['href'] ?? '';
      final absolute = seriesUrl.resolve(href);
      if (absolute.host != seriesUrl.host) continue;
      final match = ownEpisode.firstMatch(absolute.path);
      if (match == null) continue;
      final number = int.tryParse(match.group(1)!);
      if (number == null || number < 1) continue;
      candidates[number] = variant == 1
          ? _episodeUrl(slug, number) : absolute.toString();
    }
    print('[AniDB V$variant] series=$slug own episodes=${candidates.length}');
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

  Map<String, String> _streamHeaders(String episodeId) {
    final headers = <String, String>{'Referer': episodeId};
    if (variant >= 2) {
      headers['Origin'] = 'https://anidb.se';
      headers['User-Agent'] = 'Mozilla/5.0 (Linux; Android 12; Android TV) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';
    }
    return headers;
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
      for (final url in urls) {
        print('[AniDB V$variant] candidate: $url');
      }
      // Probe the same stream URL with each variant's playback headers.
      // Log status and limited response metadata, never cookies or tokens.
      for (final url in urls.take(3)) {
        final client = http.Client();
        try {
          final request = http.Request('GET', Uri.parse(url))
            ..headers.addAll({..._streamHeaders(episodeId), 'Range': 'bytes=0-1023'});
          final response = await client.send(request).timeout(const Duration(seconds: 12));
          final bytes = <int>[];
          try {
            await for (final chunk in response.stream.timeout(const Duration(seconds: 12))) {
              final remaining = 1024 - bytes.length;
              if (remaining <= 0) break;
              bytes.addAll(chunk.take(remaining));
              if (bytes.length >= 1024) break;
            }
          } catch (e) {
            print('[AniDB V$variant] Probe body read error: $e');
          }
          final prefix = utf8.decode(bytes.take(80).toList(), allowMalformed: true).toLowerCase();
          final mp4 = bytes.length >= 8 && ascii.decode(bytes.sublist(4, 8), allowInvalid: true) == 'ftyp';
          print('[AniDB V$variant] HTTP GET status=${response.statusCode} type=${response.headers['content-type']} range=${response.headers['content-range']} length=${response.headers['content-length']} bytes=${bytes.length} mp4Ftyp=$mp4 html=${prefix.contains('<html')}');
        } catch (e) {
          print('[AniDB V$variant] HTTP probe error: $e');
        } finally {
          client.close();
        }
      }
      update(urls.map((url) => VideoStream(
        url: url, quality: 'default', server: 'AniDB V' + variant.toString(),
        backup: false, customHeaders: _streamHeaders(episodeId),
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
