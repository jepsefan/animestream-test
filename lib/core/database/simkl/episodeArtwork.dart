import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:animestream/core/anime/providers/types.dart';
import 'package:animestream/core/app/env.dart';
import 'package:animestream/core/commons/enums.dart';
import 'package:animestream/core/data/secureStorage.dart';
import 'package:animestream/core/database/simkl/simkl.dart';
import 'package:animestream/core/network/caching/cache_manager.dart';
import 'package:animestream/core/network/caching/domain/cache_entry.dart';

/// Reuses the app's existing Hive-backed CacheManager and its size/clear
/// settings. Positive episode artwork never refreshes automatically.
/// Only episodes without an image are retried after 24 hours.
class SimklEpisodeArtwork {
  SimklEpisodeArtwork._();
  static final SimklEpisodeArtwork instance = SimklEpisodeArtwork._();
  final CacheManager _cache = CacheManager();
  final Map<int, Future<Map<int, String>>> _pendingLists = {};
  final Map<String, Future<Uint8List?>> _pendingImages = {};
  static const Duration _permanent = Duration(days: 3650);
  static const Duration _missingRetry = Duration(hours: 24);
  static const Duration _failedRetry = Duration(minutes: 30);

  String _listKey(int id) => 'simkl:episode-artwork:list:$id';
  String _imageKey(String url) => 'simkl:episode-artwork:image:$url';

  static String? _imageUrl(Object? raw) {
    if (raw is! String) return null;
    var path = raw.trim();
    if (path.isEmpty) return null;
    if (path.startsWith('https://simkl.in/episodes/')) {
      path = path.substring('https://simkl.in/episodes/'.length);
    }
    if (path.startsWith('https://wsrv.nl/?url=https://simkl.in/episodes/')) {
      return path;
    }
    path = path.replaceFirst(RegExp(r'_(w|c|m)\.(webp|jpg)$'), '');
    if (path.isEmpty || path.contains('..') ||
        !RegExp(r'^[a-zA-Z0-9/_-]+$').hasMatch(path)) return null;
    final url = 'https://simkl.in/episodes/' + path + '_w.webp';
    return 'https://wsrv.nl/?url=' + Uri.encodeComponent(url);
  }

  static Map<int, String> _parseEpisodes(dynamic response) {
    final items = response is List
        ? response
        : response is Map ? response['episodes'] : null;
    if (items is! List) return {};
    final images = <int, String>{};
    final ambiguous = <int>{};
    for (final item in items) {
      if (item is! Map) continue;
      // Special episodes (season 0) must not become episode 1 artwork.
      final season = int.tryParse((item['season'] ?? 1).toString());
      if (season != 1) continue;
      final number = int.tryParse(
          (item['number'] ?? item['episode_number'] ?? item['episode'] ?? '').toString());
      if (number == null || number <= 0) continue;
      final url = _imageUrl(item['img'] ?? item['image']);
      if (url == null) continue;
      if (images.containsKey(number) && images[number] != url) {
        ambiguous.add(number);
      } else {
        images[number] = url;
      }
    }
    for (final number in ambiguous) {
      images.remove(number);
    }
    return images;
  }

  Future<Map<int, String>> forEpisodes(int simklId, List<EpisodeDetails> episodes) async {
    if (simklId <= 0 || episodes.isEmpty) return const {};
    final needs = episodes
        .where((e) => e.episodeNumber > 0 &&
            (e.thumbnail == null || e.thumbnail!.trim().isEmpty))
        .map((e) => e.episodeNumber).toSet();
    if (needs.isEmpty) return const {};
    if ((await getSecureVal(SecureStorageKey.simklToken) ?? '').isEmpty ||
        AnimeStreamEnvironment.simklClientId.isEmpty) return const {};
    final active = _pendingLists[simklId];
    if (active != null) return active;
    final pending = _loadList(simklId, needs);
    _pendingLists[simklId] = pending;
    try {
      return await pending;
    } finally {
      if (identical(_pendingLists[simklId], pending)) _pendingLists.remove(simklId);
    }
  }

  Future<Map<int, String>> _loadList(int id, Set<int> needs) async {
    final config = _cache.cacheConfig;
    final useCache = config.enableCaching;
    final allowRead = useCache && !config.bypassCache;
    final key = _listKey(id);
    var found = <int, String>{};
    var retryAfter = DateTime.fromMillisecondsSinceEpoch(0);
    if (allowRead) {
      final entry = await _cache.get(key);
      if (entry != null) {
        try {
          final saved = jsonDecode(utf8.decode(entry.bodyBytes)) as Map;
          final images = saved['images'] as Map?;
          if (images != null) {
            found = images.map<int, String>((k, v) =>
                MapEntry(int.parse(k.toString()), v.toString()));
          }
          retryAfter = DateTime.fromMillisecondsSinceEpoch(
              (saved['retryAfter'] as num?)?.toInt() ?? 0);
        } catch (_) {
          found = {};
        }
      }
    }
    if (!needs.any((number) => !found.containsKey(number)) ||
        (allowRead && DateTime.now().isBefore(retryAfter))) {
      return found;
    }

    var retry = _missingRetry;
    try {
      final response = await Simkl().fetch(
          'https://api.simkl.com/anime/episodes/$id?client_id=' +
          AnimeStreamEnvironment.simklClientId);
      for (final item in _parseEpisodes(response).entries) {
        found.putIfAbsent(item.key, () => item.value);
      }
    } catch (_) {
      // Source episodes must keep working during SIMKL API outages.
      retry = _failedRetry;
    }
    if (useCache) {
      final now = DateTime.now();
      await _cache.put(key, CacheEntry(
        key: key,
        bodyBytes: utf8.encode(jsonEncode({
          'images': found.map((k, v) => MapEntry(k.toString(), v)),
          'retryAfter': now.add(retry).millisecondsSinceEpoch,
        })),
        expiry: now.add(_permanent),
      ), _permanent);
    }
    return found;
  }

  /// Binary image bytes share the exact same CacheManager/Hive cache as the
  /// metadata. A SIMKL image URL is immutable. There is no second disk cache.
  Future<Uint8List?> imageBytes(String url) {
    final active = _pendingImages[url];
    if (active != null) return active;
    final pending = _readImage(url);
    _pendingImages[url] = pending;
    pending.then((_) {
      if (identical(_pendingImages[url], pending)) _pendingImages.remove(url);
    }, onError: (_) {
      _pendingImages.remove(url);
    });
    return pending;
  }

  Future<Uint8List?> _readImage(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme != 'https' || uri.host != 'wsrv.nl' ||
        !(uri.queryParameters['url'] ?? '').startsWith(
            'https://simkl.in/episodes/')) return null;
    final config = _cache.cacheConfig;
    final key = _imageKey(url);
    if (config.enableCaching && !config.bypassCache) {
      final entry = await _cache.get(key);
      if (entry != null && entry.bodyBytes.isNotEmpty) {
        return Uint8List.fromList(entry.bodyBytes);
      }
    }
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    try {
      final request = await client.getUrl(uri);
      final response = await request.close().timeout(const Duration(seconds: 12));
      if (response.statusCode != HttpStatus.ok ||
          response.contentLength > 5 * 1024 * 1024) return null;
      final bytes = <int>[];
      await for (final part in response.timeout(const Duration(seconds: 12))) {
        bytes.addAll(part);
        if (bytes.length > 5 * 1024 * 1024) return null;
      }
      if (bytes.isEmpty) return null;
      if (config.enableCaching) {
        await _cache.put(key, CacheEntry(
          key: key, bodyBytes: bytes,
          expiry: DateTime.now().add(_permanent),
        ), _permanent);
      }
      return Uint8List.fromList(bytes);
    } catch (_) {
      return null;
    } finally {
      client.close(force: true);
    }
  }
}
