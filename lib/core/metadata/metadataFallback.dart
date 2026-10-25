import 'package:animestream/core/app/logging.dart';
import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/database/anilist/types.dart';
import 'package:animestream/core/database/database.dart';
import 'package:animestream/core/database/types.dart';
import 'package:animestream/core/metadata/kitsuMetadata.dart';
import 'package:animestream/core/metadata/malMetadata.dart';
import 'package:animestream/core/metadata/metadataTypes.dart';

/// Reads the provider-related settings once per call so a settings change takes
/// effect on the next request without a restart.
class MetadataSettings {
  const MetadataSettings._();
  static bool isEnabled(String id) =>
      !(currentUserSettings?.disabledMetadataProviders ?? const <String>[]).contains(id);

  static bool get anilistEnabled => isEnabled('anilist');

  static List<String> get fallbackOrder =>
      (currentUserSettings?.metadataFallbacks ?? const <String>['mal', 'kitsu'])
          .where((id) => (id == 'mal' || id == 'kitsu') && isEnabled(id))
          .toList(growable: false);
}

class _AnimeFallbackEntry {
  final String source;
  final String providerId;

  const _AnimeFallbackEntry(this.source, this.providerId);
}

/// Routes anime metadata to AniList's fallbacks and owns the app-local ids
/// that let fallback results travel through the existing int-id UI.
///
/// AniList ids are positive; fallback ids are negative. For MAL and Kitsu the
/// negative id is a deterministic encoding of the provider id, so a local
/// watch-history row still resolves after a restart. A registry covers any
/// provider id that is not numeric, though both current providers use numbers.
class AnimeMetadataRouter {
  AnimeMetadataRouter._();

  static final AnimeMetadataRouter instance = AnimeMetadataRouter._();

  final Map<String, AnimeMetadataProvider> _providers =
      <String, AnimeMetadataProvider>{
    'mal': MalAnimeMetadata(),
    'kitsu': KitsuAnimeMetadata(),
  };

  /// Kitsu ids are packed below this offset so a negative id can be decoded
  /// after a restart. MAL ids are simply negated: AniList ids are positive, so
  /// the two ranges cannot collide.
  static const int _kitsuOffset = 1000000000;

  final Map<int, _AnimeFallbackEntry> _entries = <int, _AnimeFallbackEntry>{};
  final Map<String, int> _ids = <String, int>{};
  int _nextId = -2000000000;

  List<AnimeMetadataProvider> get _enabled {
    final found = <AnimeMetadataProvider>[];
    for (final source in MetadataSettings.fallbackOrder) {
      final provider = _providers[source];
      if (provider != null) found.add(provider);
    }
    return found;
  }

  bool get anilistEnabled => MetadataSettings.anilistEnabled;

  /// Negative ids are fallback ids. They are deterministic for numeric
  /// provider ids, which matters because a local watch-history row outlives the
  /// in-memory registry.
  bool isFallbackId(int id) => id < 0;

  int _idFor(AnimeMetadataSummary summary) {
    final raw = int.tryParse(summary.providerId);
    if (raw != null && raw > 0) {
      return summary.source == 'mal' ? -raw : -_kitsuOffset - raw;
    }

    final key = '${summary.source}:${summary.providerId}';
    final existing = _ids[key];
    if (existing != null) return existing;
    final id = _nextId--;
    _ids[key] = id;
    _entries[id] = _AnimeFallbackEntry(summary.source, summary.providerId);
    return id;
  }

  Future<List<AnimeMetadataSummary>> _firstList(
    Future<List<AnimeMetadataSummary>> Function(AnimeMetadataProvider provider)
        fetch,
  ) async {
    Object? lastError;
    var sawEmpty = false;
    for (final provider in _enabled) {
      try {
        final result = await fetch(provider);
        if (result.isNotEmpty) return result;
        // An empty rail is not an answer: try the next provider before giving
        // up. A genuinely empty search still returns [] below.
        sawEmpty = true;
      } catch (err) {
        lastError = err;
        Logs.app.log('[metadata] ${provider.id} request failed: $err');
      }
    }
    if (sawEmpty) return const <AnimeMetadataSummary>[];
    throw MetadataUnavailableException(
      'AniList is unavailable and no metadata fallback answered.'
      '${lastError == null ? '' : ' Last error: $lastError'}',
    );
  }

  Future<List<AnilistSearchResult>> search(String query) async {
    // Only the first enabled fallback is selected, even on an empty result
    // or a network failure. This never fans out a single search.
    final available = _enabled;
    if (available.isEmpty) {
      throw const MetadataUnavailableException('No metadata provider is enabled for search.');
    }
    final list = await available.first.search(query);
    return list.map(_toSearchResult).toList(growable: false);
  }

  Future<List<TrendingResult>> trending() async {
    final list = await _firstList((provider) => provider.trending());
    return list
        .map(
          (summary) => TrendingResult(
            id: _idFor(summary),
            banner: summary.banner,
            cover: summary.cover,
            genres: summary.genres,
            rating:
                summary.rating == null ? null : (summary.rating! * 10).round(),
            title: summary.title,
          ),
        )
        .toList(growable: false);
  }

  Future<List<CurrentlyAiringResult>> currentlyAiring() async {
    final list = await _firstList((provider) => provider.currentlyAiring());
    return list
        .map(
          (summary) => CurrentlyAiringResult(
            cover: summary.cover,
            id: _idFor(summary),
            status: summary.status ?? '',
            title: summary.title,
            rating: summary.rating,
            episodes: summary.totalEpisodes,
            watchProgress: null,
          ),
        )
        .toList(growable: false);
  }

  Future<List<RecentlyUpdatedResult>> recentlyUpdated() async {
    final list = await _firstList((provider) => provider.recentlyUpdated());
    return list
        .map(
          (summary) => RecentlyUpdatedResult(
            episode: 0,
            title: summary.title,
            id: _idFor(summary),
            type: summary.format ?? 'ANIME',
            banner: summary.banner,
            cover: summary.cover,
            genres: summary.genres,
            releaseStatus: summary.status ?? '',
            rating:
                summary.rating == null ? null : (summary.rating! * 10).round(),
          ),
        )
        .toList(growable: false);
  }

  Future<List<AnilistRecommendations>> recommended() async {
    final list = await _firstList((provider) => provider.recommended());
    return list
        .map(
          (summary) => AnilistRecommendations(
            cover: summary.cover,
            id: _idFor(summary),
            title: summary.title,
            rating: summary.rating,
          ),
        )
        .toList(growable: false);
  }

  AnilistSearchResult _toSearchResult(AnimeMetadataSummary summary) {
    return AnilistSearchResult(
      cover: summary.cover,
      id: _idFor(summary),
      isAdult: summary.isAdult,
      ageRating: summary.ageRating,
      idMal:
          summary.source == 'mal' ? int.tryParse(summary.providerId) : null,
      title: summary.title,
      rating: summary.rating,
      totalEpisodes: summary.totalEpisodes,
    );
  }

  Future<AnilistInfo> info(int id) async {
    String? source;
    String? providerId;

    // Registry entries first: a non-numeric provider id uses a synthetic slot
    // that must not be decoded as a MAL id.
    final entry = _entries[id];
    if (entry != null) {
      source = entry.source;
      providerId = entry.providerId;
    } else if (id <= -_kitsuOffset) {
      source = 'kitsu';
      providerId = (-(id + _kitsuOffset)).toString();
    } else if (id < 0) {
      source = 'mal';
      providerId = (-id).toString();
    }

    if (source == null || providerId == null) {
      throw MetadataUnavailableException('Unknown fallback id: $id');
    }
    final provider = _providers[source];
    if (provider == null) {
      throw MetadataUnavailableException('Unknown fallback provider: $source');
    }
    return _toInfo(await provider.details(providerId));
  }

  AnilistInfo _toInfo(AnimeMetadataDetails details) {
    final summary = details.summary;
    final alternate = <AlternateDatabaseId>[];
    if (summary.source == 'mal') {
      final malId = int.tryParse(summary.providerId);
      if (malId != null) {
        alternate.add(AlternateDatabaseId(database: Databases.mal, id: malId));
      }
    }

    return AnilistInfo(
      isAdult: summary.isAdult,
      ageRating: summary.ageRating,
      aired: <String, String>{
        'start': details.startDate ?? '',
        'end': details.endDate ?? '',
      },
      banner: details.banner ?? summary.banner,
      characters: List<Map<String, dynamic>>.of(details.characters),
      cover: summary.cover,
      duration: details.duration ?? '??',
      episodes: details.episodes ?? summary.totalEpisodes,
      genres: details.genres,
      mediaListStatus: null,
      nextAiringEpisode: (airingAt: '', timeLeft: '', episode: ''),
      rating: details.rating ?? summary.rating,
      recommended: _toRelated(details.recommended),
      related: _toRelated(details.related),
      status: details.status ?? summary.status,
      studios: details.studios,
      synonyms: details.synonyms,
      synopsis: details.synopsis,
      tags: const <String>[],
      title: summary.title,
      type: details.type ?? summary.format ?? 'ANIME',
      alternateDatabases: alternate,
      listId: null,
    );
  }

  List<AnilistAnimeRelatedRecommendation> _toRelated(
    List<AnimeMetadataSummary> list,
  ) {
    return list
        .map(
          (summary) => AnilistAnimeRelatedRecommendation(
            cover: summary.cover,
            id: _idFor(summary),
            isAdult: summary.isAdult,
            ageRating: summary.ageRating,
            rating: summary.rating,
            title: summary.title,
            type: summary.isManga ? 'MANGA' : (summary.format ?? 'ANIME'),
            relationType: summary.relationType ?? (summary.isManga ? 'Adaptation' : 'Related'),
          ),
        )
        .toList(growable: true);
  }
}

