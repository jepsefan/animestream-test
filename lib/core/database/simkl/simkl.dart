import 'dart:convert';

import 'package:animestream/core/app/env.dart';
import 'package:animestream/core/app/logging.dart';
import 'package:animestream/core/commons/enums.dart';
import 'package:animestream/core/data/secureStorage.dart';
import 'package:animestream/core/database/database.dart';
import 'package:animestream/core/database/simkl/types.dart';
import 'package:animestream/core/network/network.dart';

class Simkl extends Database {
  static String imageLink(String url, {bool fanart = false}) =>
      "https://wsrv.nl/?url=https://simkl.in/${fanart ? "fanart" : "posters"}/${url}${fanart ? "_w" : "_ca"}.webp";

  Future<List<SimklSearchResult>> search(String query) async {
    final url =
        "https://api.simkl.com/search/anime?q=$query&client_id=${AnimeStreamEnvironment.simklClientId}";

    Logs.app.log("[SIMKL LOOKUP]: query=$query");

    final response = await get(
      Uri.parse(url),
      headers: await _authenticatedHeaders(),
    );

    Logs.app.log(
      "[SIMKL LOOKUP]: HTTP ${response.statusCode}: ${response.body}",
    );

    if (response.statusCode < 200 || response.statusCode > 299) {
      throw Exception(
        "ERR_COULDNT_FETCH_SIMKL_SEARCH_${response.statusCode}: ${response.body}",
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      Logs.app.log(
        "[SIMKL LOOKUP]: unexpected response type ${decoded.runtimeType}",
      );
      throw Exception("ERR_INVALID_SIMKL_SEARCH_RESPONSE");
    }

    final List<dynamic> res = decoded;
    Logs.app.log("[SIMKL LOOKUP]: results=${res.length}");

    List<SimklSearchResult> sr = [];
    res.forEach((it) {
      final simklId = it['ids']?['simkl_id'];
      Logs.app.log("[SIMKL LOOKUP]: resolved simklId=$simklId");

      sr.add(SimklSearchResult(
        cover: imageLink(it['poster']),
        id: simklId,
        title: {
          'english': it['title_en'] ?? it['title'],
          'romaji': it['title_romaji'] ?? it['title']
        },
      ));
    });

    return sr;
  }

  Future<SimklInfo> getAnimeInfo(int id) async {
    final url =
        "https://api.simkl.com/anime/$id?extended=full&client_id=${AnimeStreamEnvironment.simklClientId}";
    final res = await fetch(url);
    final datafied = SimklInfo.fromJson(res);
    return datafied;
  }

  /// Read-only Rewatch discovery. Call only after account eligibility is verified.
  /// This never starts a rewatch or modifies watch history.
  Future<List<SimklRewatchSession>> getRewatchSessions() async {
    final token = await getSecureVal(SecureStorageKey.simklToken);
    if (token == null || token.isEmpty) return const [];

    final uri = Uri.https('api.simkl.com', '/sync/all-items/anime/all', {
      'allow_rewatch': 'yes',
      'extended': 'full',
      'episode_watched_at': 'yes',
    });
    final response = await get(uri, headers: await _authenticatedHeaders());
    if (response.statusCode < 200 || response.statusCode >= 300) {
      Logs.app.log('[SIMKL REWATCH] Fetch failed: HTTP ${response.statusCode}');
      throw SimklException('Could not fetch Rewatch sessions', response.statusCode);
    }
    final payload = jsonDecode(response.body);
    if (payload is! Map) throw const FormatException('Invalid SIMKL list response');
    // Log response shape only. Never log titles, IDs, dates, tokens, or values.
    String shapeOf(dynamic value) {
      if (value is Map) {
        final keys = value.keys.whereType<String>().toList()..sort();
        return '{${keys.join(',')}}';
      }
      if (value is List) return 'list(length=${value.length})';
      return value == null ? 'null' : value.runtimeType.toString();
    }

    Logs.app.log('[SIMKL REWATCH SHAPE] root=${shapeOf(payload)}');
    for (final category in ['anime', 'shows']) {
      final entries = payload[category];
      Logs.app.log('[SIMKL REWATCH SHAPE] $category=${shapeOf(entries)}');
      if (entries is! List) continue;
      // Inspect one rewatch entry only, to avoid excessive logs.
      Map? sample;
      for (final item in entries) {
        if (item is Map && item['is_rewatch'] == true) {
          sample = item;
          break;
        }
      }
      if (sample == null) continue;
      Logs.app.log('[SIMKL REWATCH SHAPE] $category rewatchEntry=${shapeOf(sample)}');
      for (final field in [
        'rewatch_episodes', 'episodes', 'rewatch', 'rewatches',
        'episode_watched_at', 'watched_episodes', 'show',
      ]) {
        final nested = sample[field];
        if (nested == null) continue;
        Logs.app.log('[SIMKL REWATCH SHAPE] $category.$field=${shapeOf(nested)}');
        if (nested is List && nested.isNotEmpty) {
          Logs.app.log('[SIMKL REWATCH SHAPE] $category.$field.first=${shapeOf(nested.first)}');
        }
        if (nested is Map) {
          for (final child in ['episodes', 'rewatch_episodes', 'watched_episodes']) {
            if (!nested.containsKey(child)) continue;
            final childValue = nested[child];
            Logs.app.log('[SIMKL REWATCH SHAPE] $category.$field.$child=${shapeOf(childValue)}');
            if (childValue is List && childValue.isNotEmpty) {
              Logs.app.log('[SIMKL REWATCH SHAPE] $category.$field.$child.first=${shapeOf(childValue.first)}');
            }
          }
        }
      }
    }
    final sessions = <SimklRewatchSession>[];
    for (final category in ['anime', 'shows']) {
      final entries = payload[category];
      if (entries is! List) continue;
      for (final entry in entries) {
        if (entry is! Map || entry['is_rewatch'] != true) continue;
        final ids = entry['show'] is Map ? entry['show']['ids'] : entry['ids'];
        final id = ids is Map ? (ids['simkl'] ?? ids['simkl_id']) : null;
        final sessionId = entry['rewatch_id'];
        if (id is! num || sessionId == null) continue;
        // Never infer session progress from global watched flags.
        final watchedEpisodes = <int>{};
        final sessionEpisodes = entry['rewatch_episodes'];
        if (sessionEpisodes is List) {
          for (final item in sessionEpisodes) {
            if (item is! Map) continue;
            final raw = item['episode_number'] ?? item['number'];
            final number = raw is num ? raw.toInt() : int.tryParse('$raw');
            if (number != null && number > 0 &&
                (item['watched'] == true || item['is_watched'] == true)) {
              watchedEpisodes.add(number);
            }
          }
        }
        sessions.add(SimklRewatchSession(
          animeId: id.toInt(),
          rewatchId: sessionId.toString(),
          status: entry['rewatch_status']?.toString() ?? 'unknown',
          watchedEpisodes: watchedEpisodes,
        ));
      }
    }
    Logs.app.log('[SIMKL REWATCH] Read-only discovery: ${sessions.length} sessions');
    return sessions;
  }

  Future<dynamic> fetch(String url) async {
    final res = await get(
      Uri.parse(url),
      headers: await _authenticatedHeaders(),
    );

    //since 2** means success
    if (res.statusCode < 200 || res.statusCode > 299) {
      throw Exception(
        "ERR_COULDNT_FETCH_SIMKL_${res.statusCode}: ${res.body}",
      );
    }
    return jsonDecode(res.body);
  }

  Future<Map<String, String>> _authenticatedHeaders() async {
    final token = await getSecureVal(SecureStorageKey.simklToken);

    final headers = <String, String>{
      'Accept': 'application/json',
      'simkl-api-key': AnimeStreamEnvironment.simklClientId,
    };

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }
}
