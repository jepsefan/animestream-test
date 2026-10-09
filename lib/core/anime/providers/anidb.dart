import 'package:animestream/core/anime/providers/animeProvider.dart';
import 'package:animestream/core/anime/providers/types.dart';
import 'package:animestream/core/app/logging.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart' as html;
import 'package:animestream/core/network/network.dart';

abstract class AniDBSeBase implements AnimeProvider {
  static const baseUrl = "https://anidb.se";
  static const Map<String, String> headers = {
    "User-Agent":
        "Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 Chrome/124 Safari/537.36",
    "Accept":
        "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
  };

  String get variantName;

  Uri buildSearchUri(String query);

  @override
  Future<List<Map<String, String?>>> search(String query) async {
    final uri = buildSearchUri(query);
    Logs.app.log("[ANIDB.SE $variantName] search: $uri");

    final res = await get(
      uri,
      headers: AniDBSeBase.headers,
      cacheDuration: const Duration(minutes: 5),
    );

    Logs.app.log(
      "[ANIDB.SE $variantName] search HTTP ${res.statusCode}, bytes=${res.body.length}",
    );

    final document = html.parse(res.body);
    final results = _extractAnimeResults(document, query);

    Logs.app.log(
      "[ANIDB.SE $variantName] search results=${results.length}",
    );

    return results;
  }

  List<Map<String, String?>> _extractAnimeResults(
    Document document,
    String query,
  ) {
    final results = <Map<String, String?>>[];
    final seen = <String>{};

    void addAnchor(Element anchor) {
      final href = anchor.attributes['href'];
      if (href == null || !href.contains('/anime/')) return;

      final uri = Uri.tryParse(href);
      final path = uri?.path ?? href;
      if (path == '/anime/' || path == '/anime') return;

      final absolute = Uri.parse(AniDBSeBase.baseUrl).resolve(href).toString();
      if (!seen.add(absolute)) return;

      final img = anchor.querySelector('img');
      final title = _cleanText(
        anchor.attributes['title'] ??
            img?.attributes['alt'] ??
            anchor.querySelector('h1,h2,h3,h4,p,.title')?.text ??
            anchor.text,
      );

      if (title.isEmpty) return;

      results.add({
        'name': title,
        'alias': absolute,
        'imageUrl': img?.attributes['src'],
      });
    }

    for (final selector in [
      'a[href*="/anime/"]',
      '.anime-grid a',
      'article a[href*="/anime/"]',
      '.search-results a[href*="/anime/"]',
    ]) {
      for (final anchor in document.querySelectorAll(selector)) {
        addAnchor(anchor);
      }
    }

    return results;
  }

  @override
  Future<List<Map<String, dynamic>>> getAnimeEpisodeLink(
    String aliasId, {
    bool dub = false,
  }) async {
    final animeUri = Uri.tryParse(aliasId)?.hasScheme == true
        ? Uri.parse(aliasId)
        : Uri.parse(AniDBSeBase.baseUrl).resolve(aliasId);

    Logs.app.log("[ANIDB.SE $variantName] anime page: $animeUri");

    final res = await get(
      animeUri,
      headers: headers,
      cacheDuration: const Duration(minutes: 5),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('AniDB series HTTP ${res.statusCode}: $animeUri');
    }

    final document = html.parse(res.body);
    final slug = animeUri.pathSegments.where((s) => s.isNotEmpty).last;
    final numbers = <int>{};
    final numberPattern = RegExp(r'(?:episode|ep)[\s#:_-]*(\d+)', caseSensitive: false);
    final expected = RegExp(
      '^${RegExp.escape(slug)}-episode-([0-9]+)-english-subbed/?' + r'$',
      caseSensitive: false,
    );
    // V1: only series-specific episode hyperlinks.
    if (variantName == 'v1' || variantName == 'v3') {
      for (final anchor in document.querySelectorAll('a[href]')) {
        final href = anchor.attributes['href'];
        if (href == null || href == '#') continue;
        final uri = animeUri.resolve(href);
        if (uri.host != animeUri.host) continue;
        final match = expected.firstMatch(uri.path.replaceFirst(RegExp(r'^/'), ''));
        if (match != null) numbers.add(int.parse(match.group(1)!));
      }
    }
    // V2: only controls within episode widgets, not recommendations.
    if (variantName == 'v2' || variantName == 'v3') {
      for (final element in document.querySelectorAll(
        '.eplister a, .episodelist a, .episode-list a, '
        '[data-episode], [data-ep], [data-number]',
      )) {
        final descriptor = '${element.text} ${element.attributes['title'] ?? ''} '
            '${element.attributes['data-episode'] ?? ''} '
            '${element.attributes['data-ep'] ?? ''}';
        final match = numberPattern.firstMatch(descriptor);
        if (match != null) numbers.add(int.parse(match.group(1)!));
      }
    }
    Logs.app.log('[ANIDB.SE $variantName] candidates=${numbers.length}');
    final episodes = <Map<String, dynamic>>[];
    for (final number in numbers.toList()..sort()) {
      final episodeUri = Uri.parse(
        '$baseUrl/$slug-episode-$number-english-subbed/',
      );
      try {
        final episodeRes = await get(
          episodeUri,
          headers: headers,
          cacheDuration: const Duration(minutes: 5),
        );
        if (episodeRes.statusCode != 200) {
          Logs.app.log('[ANIDB.SE $variantName] skipping episode $number: '
              'HTTP ${episodeRes.statusCode}');
          continue;
        }
        final page = html.parse(episodeRes.body);
        final canonical = page.querySelector('link[rel="canonical"]')
            ?.attributes['href'];
        if (canonical != null &&
            episodeUri.resolve(canonical).path != episodeUri.path) {
          Logs.app.log('[ANIDB.SE $variantName] skipping episode $number: '
              'canonical mismatch');
          continue;
        }
        // Dynamic players are injected after page load; validate page identity
        // instead of requiring video elements in the initial HTML.
        final title = [
          page.querySelector('title')?.text ?? '',
          page.querySelector('h1')?.text ?? '',
          page.querySelector('meta[property="og:title"]')?.attributes['content'] ?? '',
        ].join(' ').toLowerCase();
        final normalized = title.replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
        if (!normalized.contains(slug.replaceAll('-', ' ')) ||
            !RegExp('episode\\s*$number\\b', caseSensitive: false).hasMatch(title)) {
          Logs.app.log('[ANIDB.SE $variantName] skipping episode $number: title mismatch');
          continue;
        }
        episodes.add({
          'episodeLink': episodeUri.toString(),
          'episodeNumber': number.toString(),
          'episodeTitle': 'Episode $number',
          'thumbnail': null,
          'hasDub': false,
          'isFiller': false,
        });
      } catch (error) {
        Logs.app.log('[ANIDB.SE $variantName] episode $number failed: $error');
      }
    }
    Logs.app.log('[ANIDB.SE $variantName] verified episodes=${episodes.length}');
    return episodes;
  }

  String? _episodeNumber(String text, String href) {
    final patterns = [
      RegExp(r'episode[\s_-]*(\d+(?:\.\d+)?)', caseSensitive: false),
      RegExp(r'ep[\s_-]*(\d+(?:\.\d+)?)', caseSensitive: false),
    ];

    for (final source in [text, href]) {
      for (final pattern in patterns) {
        final match = pattern.firstMatch(source);
        if (match != null) return match.group(1);
      }
    }

    return null;
  }

  @override
  Future<void> getStreams(
    String episodeId,
    Function(List<VideoStream>, bool) update, {
    bool dub = false,
    String? metadata,
  }) async {
    final rawEpisodeUri = Uri.tryParse(episodeId)?.hasScheme == true
        ? Uri.parse(episodeId)
        : Uri.parse(AniDBSeBase.baseUrl).resolve(episodeId);

    final requestedEpisode = rawEpisodeUri.fragment.startsWith('episode=')
        ? rawEpisodeUri.fragment.substring('episode='.length)
        : null;

    final episodeUri = rawEpisodeUri.replace(fragment: '');

    Logs.app.log(
      "[ANIDB.SE $variantName] episode page: $episodeUri"
      "${requestedEpisode == null ? '' : ' (episode=$requestedEpisode)'}",
    );

    final found = <String>{};
    await _extractStreamsFromPage(
      episodeUri,
      found,
      update,
      depth: 0,
      requestedEpisode: requestedEpisode,
    );

    Logs.app.log(
      "[ANIDB.SE $variantName] streams=${found.length}",
    );
    update([], true);
  }

  Future<void> _extractStreamsFromPage(
    Uri uri,
    Set<String> found,
    Function(List<VideoStream>, bool) update, {
    required int depth,
    String? requestedEpisode,
  }) async {
    final res = await get(
      uri,
      headers: headers,
      cacheDuration: const Duration(minutes: 15),
    );

    final body = res.body;
    final document = html.parse(body);

    final candidates = <String>{};

    // If the episode selector points back to the anime page, inspect the
    // matching episode control and nearby container first. This avoids
    // accidentally scanning a different episode's hidden player.
    if (requestedEpisode != null && depth == 0) {
      final episodePattern = RegExp(
        'episode\\s*' + RegExp.escape(requestedEpisode) + r'\\b',
        caseSensitive: false,
      );

      for (final element in document.querySelectorAll(
        'a, button, [data-episode], [data-number], [data-ep]',
      )) {
        final descriptor =
            '${element.text} ${element.attributes.values.join(' ')}';

        if (!episodePattern.hasMatch(descriptor)) continue;

        Element? scope = element;
        for (var level = 0; level < 4 && scope != null; level++) {
          final scopeHtml = scope.outerHtml;

          for (final pattern in [
            RegExp(r'''https?://[^"'\\s<>]+\\.m3u8[^"'\\s<>]*''',
                caseSensitive: false),
            RegExp(r'''(?:src|file|source|url|embed)\\s*[:=]\\s*["']([^"']+)["']''',
                caseSensitive: false),
          ]) {
            for (final match in pattern.allMatches(scopeHtml)) {
              final value =
                  match.groupCount > 0 ? match.group(1) : match.group(0);
              if (value != null &&
                  (value.contains('.m3u8') ||
                      value.contains('/embed') ||
                      value.contains('/player'))) {
                candidates.add(uri.resolve(value).toString());
              }
            }
          }

          for (final frame in scope.querySelectorAll(
            'iframe[src], embed[src], video[src], video source[src]',
          )) {
            final value = frame.attributes['src'];
            if (value != null && value.isNotEmpty) {
              candidates.add(uri.resolve(value).toString());
            }
          }

          scope = scope.parent;
        }
      }
    }

    for (final pattern in [
      RegExp(r'''https?://[^"'\s<>]+\.m3u8[^"'\s<>]*''',
          caseSensitive: false),
      RegExp(r'''file\s*[:=]\s*["']([^"']+)["']''',
          caseSensitive: false),
      RegExp(r'''source\s*[:=]\s*["']([^"']+)["']''',
          caseSensitive: false),
    ]) {
      for (final match in pattern.allMatches(body)) {
        final value = match.groupCount > 0 ? match.group(1) : match.group(0);
        if (value != null && value.contains('.m3u8')) {
          candidates.add(Uri.parse(AniDBSeBase.baseUrl).resolve(value).toString());
        }
      }
    }

    for (final element in document.querySelectorAll(
      'video source[src], video[src], a[href*=".m3u8"]',
    )) {
      final value = element.attributes['src'] ?? element.attributes['href'];
      if (value != null) {
        candidates.add(uri.resolve(value).toString());
      }
    }

    Logs.app.log(
      "[ANIDB.SE $variantName] stream candidates=${candidates.length}"
      "${requestedEpisode == null ? '' : ' for episode $requestedEpisode'}",
    );

    for (final url in candidates) {
      if (!found.add(url)) continue;
      update(
        [
          VideoStream(
            url: url,
            quality: 'default',
            server: 'AniDB.se $variantName',
            backup: false,
            customHeaders: headers,
          ),
        ],
        false,
      );
    }

    if (found.isNotEmpty || depth >= 1) return;

    final embeds = <String>{};
    for (final element in document.querySelectorAll('iframe[src], embed[src]')) {
      final src = element.attributes['src'];
      if (src != null && src.isNotEmpty) {
        embeds.add(uri.resolve(src).toString());
      }
    }

    for (final embed in embeds.take(5)) {
      try {
        await _extractStreamsFromPage(
          Uri.parse(embed),
          found,
          update,
          depth: depth + 1,
          requestedEpisode: requestedEpisode,
        );
      } catch (err) {
        Logs.app.log(
          "[ANIDB.SE $variantName] embed failed: $embed -> $err",
        );
      }
    }
  }

  String _cleanText(String value) =>
      value.replaceAll(RegExp(r'\s+'), ' ').trim();

  @override
  Future<void> getDownloadSources(
    String episodeUrl,
    Function(List<VideoStream>, bool) update, {
    bool dub = false,
    String? metadata,
  }) async {
    throw UnimplementedError();
  }
}

/// v1: use the site's normal WordPress-style search, matching the URL
/// visible in the browser: https://anidb.se/?s=<title>
class AniDBSeV1 extends AniDBSeBase {
  @override
  final String providerName = "AniDB.se v1";

  @override
  String get variantName => "v1";

  @override
  Uri buildSearchUri(String query) {
    return Uri.parse(AniDBSeBase.baseUrl).replace(
      queryParameters: {'s': query},
    );
  }
}

/// v2: search through the /anime/ archive with the same search parameter.
/// Kept separate so it can be tested independently if the root search
/// template changes.
class AniDBSeV2 extends AniDBSeBase {
  @override
  final String providerName = "AniDB.se v2";

  @override
  String get variantName => "v2";

  @override
  Uri buildSearchUri(String query) {
    return Uri.parse('${AniDBSeBase.baseUrl}/anime/').replace(
      queryParameters: {'s': query},
    );
  }
}

/// v3: direct English-title slug lookup. This matches URLs such as:
/// /anime/the-exiled-heavy-knight-knows-how-to-game-the-system/
class AniDBSeV3 extends AniDBSeBase {
  @override
  final String providerName = "AniDB.se v3";

  @override
  String get variantName => "v3";

  @override
  Uri buildSearchUri(String query) {
    final slug = query
        .toLowerCase()
        .replaceAll(RegExp(r"['’]"), '')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');

    return Uri.parse('${AniDBSeBase.baseUrl}/anime/$slug/');
  }

  @override
  Future<List<Map<String, String?>>> search(String query) async {
    final uri = buildSearchUri(query);
    Logs.app.log("[ANIDB.SE v3] direct slug: $uri");

    final res = await get(
      uri,
      headers: AniDBSeBase.headers,
      cacheDuration: const Duration(minutes: 5),
    );

    if (res.statusCode < 200 || res.statusCode >= 400) {
      Logs.app.log("[ANIDB.SE v3] direct slug HTTP ${res.statusCode}");
      return [];
    }

    final document = html.parse(res.body);
    final title = document
            .querySelector('h1')
            ?.text
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim() ??
        query;

    return [
      {
        'name': title,
        'alias': uri.toString(),
        'imageUrl': document
            .querySelector('img')
            ?.attributes['src'],
      }
    ];
  }
}

// Keep the old class name as an alias for compatibility with any old code.
class AniDB extends AniDBSeV1 {}
