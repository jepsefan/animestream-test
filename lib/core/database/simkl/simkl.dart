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
