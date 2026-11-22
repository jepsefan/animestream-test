import 'package:animestream/core/app/logging.dart';
import 'package:animestream/core/commons/enums.dart';
import 'package:animestream/core/database/anilist/login.dart';
import 'package:animestream/core/database/anilist/queries.dart';
import 'package:animestream/core/database/anilist/types.dart';
import 'package:animestream/core/database/handler/syncHandler.dart';
import 'package:animestream/core/database/local/local.dart';
import 'package:animestream/core/database/local/types.dart';
import 'package:animestream/core/database/simkl/login.dart';
import 'package:animestream/core/database/types.dart';

Future<bool> usesLocalTracker(int id) async =>
    id < 0 ||
    (!await AniListLogin().isAnilistLoggedIn() &&
        !await SimklLogin.isLoggedIn());

Future<void> storeWatching(
  String title,
  String imageUrl,
  int id,
  int watched, {
  int? totalEpisodes,
  List<AlternateDatabaseId>? alternateDatabases,
  double? rating,
  Map<String, String?>? titles,
}) async {
  try {
    if (await usesLocalTracker(id)) {
      await LocalTracker().mutateAnimeList(
        id: id,
        status: MediaStatus.CURRENT,
        progress: watched,
        otherIds: alternateDatabases,
        meta: LocalMeta(
          title: titles ?? {'english': title, 'romaji': title},
          cover: imageUrl,
          totalEpisodes: totalEpisodes,
          rating: rating,
        ),
      );
    } else {
      await SyncHandler().mutateAnimeList(
        id: id,
        status: MediaStatus.CURRENT,
        progress: watched,
        otherIds: alternateDatabases,
      );
    }
  } catch (error) {
    Logs.app.log(error.toString());
  }
}

Future<void> updateWatching(int? id, String title, int watched,
    List<AlternateDatabaseId> otherIds) async {
  if (id == null) return;
  try {
    if (await usesLocalTracker(id)) {
      await LocalTracker()
          .mutateAnimeList(id: id, progress: watched, otherIds: otherIds);
    } else {
      await SyncHandler().mutateAnimeList(
        id: id,
        status: MediaStatus.CURRENT,
        previousStatus: MediaStatus.CURRENT,
        progress: watched,
        otherIds: otherIds,
      );
    }
  } catch (error) {
    Logs.app.log(error.toString());
  }
}

Future<List<UserAnimeListItem>> getWatchedList({String? userName}) async {
  final lists = userName != null && await AniListLogin().isAnilistLoggedIn()
      ? await AnilistQueries()
          .getUserAnimeList(userName, status: MediaStatus.CURRENT)
      : await LocalTracker()
          .getUserAnimeList('', status: [MediaStatus.CURRENT]);
  return lists.isEmpty ? [] : lists.first.list.reversed.toList();
}

Future<({int? progress, String? status, int? listId})> getAnimeWatchProgress(
    int id) async {
  if (id >= 0 && await AniListLogin().isAnilistLoggedIn()) {
    return AnilistQueries().getAnimeWatchProgress(id);
  }
  final entry = await LocalTracker().getAnimeWatchProgress(id);
  return (progress: entry.progress, status: entry.status, listId: null);
}

Future<void> removeWatching(int id) async {
  try {
    await LocalTracker().deleteAnimeEntry(id: id);
  } catch (error) {
    Logs.app
        .log('${error.runtimeType} while removing from local watching list');
  }
}
