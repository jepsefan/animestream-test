import 'dart:convert';

import 'package:animestream/core/anime/providers/animeProvider.dart';
import 'package:animestream/core/anime/providers/types.dart';
import 'package:animestream/core/anime/providers/aniZoneEpisodeIdentity.dart';
import 'package:html/parser.dart';
import 'package:animestream/core/network/network.dart';

class AniZone extends AnimeProvider {
  final baseUrl = "https://anizone.to";

  @override
  Future<List<Map<String, String?>>> search(String query) async {
    final url = "$baseUrl/anime?search=$query";
    final res = await get(
      Uri.parse(url),
      cacheDuration: const Duration(minutes: 5),
    );

    final doc = parse(res.body);
    // final grid = doc.querySelector("ul.grid.grid-cols-1.gap-4");
    // if (grid == null) {
    //   throw Exception("Got list of children as null.");
    // }
    // final children = grid.querySelectorAll("li");

    final data = doc.querySelector("main")?.children[1];

    final divData = data?.attributes['x-data'];

    final matchRegEx = RegExp(r"JSON\.parse\('(.+?)'\)", dotAll: true);

    final match = matchRegEx.firstMatch(divData ?? "");

    if (match == null) {
      throw Exception("Couldn't find anime data while searching");
    }

    final parsedJson = List.castFrom(jsonDecode(match.group(1)!.replaceAll(r'\u0022', '"')));

    final List<Map<String, String?>> searchRes = [];

    for (final item in parsedJson) {
      final title = item['main_title'];
      final img = item['cover'];
      final href = item['url'];
      if (img == null || href == null || title == null) {
        throw Exception("Found null image/title/url.");
      }

      searchRes.add({
        'name': title,
        'alias': href.replaceAll("\\", ""),
        'imageUrl': img,
      });
    }

    return searchRes;
  }

  @override
  Future<List<Map<String, dynamic>>> getAnimeEpisodeLink(String aliasId, {bool dub = false}) async {
    final url = aliasId;
    final res = await get(
      Uri.parse(url),
      cacheDuration: const Duration(minutes: 5),
    );
    final doc = parse(res.body);

    final dataDiv = doc.querySelector("main")?.children.firstOrNull;

    if (dataDiv == null) {
      throw Exception("Coudlnt find the data div for episodes.");
    }

    final divData = dataDiv.attributes['x-data'];
    final matchRegEx = RegExp(r"items:\s*JSON\.parse\('(.+?)'\)", dotAll: true);

    final match = matchRegEx.firstMatch(divData ?? "");

    if (match == null || match.group(1) == null) {
      throw Exception("Couldn't find episodes data");
    }

    final matchedStr = match.group(1)!.replaceAll(r'\u0022', '"');

    final List<Map<String, dynamic>> list = List.castFrom(jsonDecode(matchedStr));

    final epList = <Map<String, dynamic>>[];

    var regularIndex = 0;
    var specialIndex = 0;
    final earlySpecials = <Map<String, dynamic>>[];

    for (final item in list) {
      final title = item['title_list']?['1']?.toString();
      final epLink = item['url']?.toString();
      if (epLink == null || epLink.isEmpty) continue;

      final episodeUrl = epLink.replaceAll(r'\', '');
      final episodeType = item['type']?.toString();
      final isSpecial = AniZoneEpisodeIdentity.isSpecial(episodeUrl, episodeType);
      if (isSpecial) {
        specialIndex++;
      } else {
        regularIndex++;
      }

      final identity = AniZoneEpisodeIdentity.fromSource(
        animeUrl: aliasId,
        episodeUrl: episodeUrl,
        title: title,
        type: episodeType,
        regularIndex: regularIndex,
        specialIndex: specialIndex,
      );
      final preview = item['snapshot']?.toString().replaceAll(r'\', '');
      final episode = <String, dynamic>{
        'episodeLink': episodeUrl,
        'episodeNumber': identity.number,
        'episodeLabel': identity.label,
        'thumbnail': preview,
        'episodeTitle': title,
        'isFiller': episodeType?.toLowerCase() == 'filler',
        'hasDub': false,
      };
      // Only move a verified prequel special. Other sN items retain their
      // source positions, as not every special aired before episode 1.
      if (identity.moveBeforeRegularEpisodes) {
        earlySpecials.add(episode);
      } else {
        epList.add(episode);
      }
    }
    epList.insertAll(0, earlySpecials);

    return epList;
  }

  @override
  Future<void> getDownloadSources(String episodeUrl, Function(List<VideoStream> p1, bool p2) update,
      {bool dub = false, String? metadata}) {
    throw UnimplementedError();
  }

  @override
  Future<void> getStreams(String episodeId, Function(List<VideoStream> p1, bool p2) update,
      {bool dub = false, String? metadata}) async {
    final url = episodeId;
    final res = await get(
      Uri.parse(url),
      cacheDuration: const Duration(hours: 1),
    );
    final doc = parse(res.body);

    final dataDiv = doc.querySelector("div.mb-8")?.children[0];
    final datas = dataDiv?.attributes['x-data'];

    if (datas == null) {
      throw Exception("Couldnt find data for the stream");
    }

    final matchRegEx = RegExp(r"JSON\.parse\('(.+?)'\)", dotAll: true);

    final match = matchRegEx.firstMatch(datas);

    if (match == null || match.group(1) == null) {
      throw Exception("Couldn't find anime data");
    }

    final streamData = jsonDecode(match.group(1)!.replaceAll(r"\u0022", '"'));

    final src = streamData['src']?.replaceAll("\\", "");
    final subs = List.castFrom(streamData['subtitles']).where((it) => it['language'] == 'en' && it['default'] == true);
    final String? firstSubUrl = subs.firstOrNull?['file']?.replaceAll("\\", "");
    // print(subs);

    final srcName = doc.querySelector("button.flex.gap-2.relative")?.text.trim() ?? "Default";

    update([
      VideoStream(
          quality: "multi-quality",
          url: src,
          server: srcName,
          subtitle: firstSubUrl,
          subtitleFormat: subs.first['format'],
          backup: false)
    ], true);
  }

  @override
  String get providerName => "anizone";
}
