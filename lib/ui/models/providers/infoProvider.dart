import 'package:animestream/core/anime/providers/episodeProgress.dart';
import 'package:animestream/core/data/localEpisodeZeroProgress.dart';
import 'package:flutter/material.dart';

import 'package:animestream/core/anime/providers/providerDetails.dart';
import 'package:animestream/core/anime/providers/aniyomiExtensionProvider.dart';
import 'package:animestream/core/anime/providers/extensionAniListMatcher.dart';
import 'package:animestream/core/anime/providers/types.dart';
import 'package:animestream/core/app/logging.dart';
import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/commons/enums.dart';
import 'package:animestream/core/commons/utils.dart';
import 'package:animestream/core/data/animeSpecificPreference.dart';
import 'package:animestream/core/data/preferences.dart';
import 'package:animestream/core/data/types.dart';
import 'package:animestream/core/data/watching.dart';
import 'package:animestream/core/database/anilist/login.dart';
import 'package:animestream/core/database/database.dart';
import 'package:animestream/core/database/handler/handler.dart';
import 'package:animestream/core/database/types.dart';
import 'package:animestream/ui/models/snackBar.dart';
import 'package:animestream/ui/models/sources.dart';
import 'package:animestream/core/anime/providers/externalAssPreferences.dart';
import 'package:animestream/core/database/simkl/episodeArtwork.dart';
import 'package:animestream/core/metadata/metadataFallback.dart';
import 'package:animestream/core/metadata/malMetadata.dart';
import 'package:animestream/core/database/anilist/types.dart';

class InfoProvider extends ChangeNotifier {
  int id;
  InfoProvider(int id) : this.id = id;

  late DatabaseInfo _data;

  final sourceManager = SourceManager.instance;

  // Will be set in _init()
  late ProviderDetails _selectedSource;

  String? _foundName;
  String? _manualSearchQuery;
  Map<String, String> _extensionSelections = {};
  final Set<String> _attemptedSavedExtensionLinks = {};
  String? _extensionLookupStage;
  String? _extensionEpisodeDiagnostic;

  /// Safe diagnostic stages without video URLs, headers or credentials.
  String? get extensionEpisodeDiagnostic => _extensionEpisodeDiagnostic;
  String? _extensionCover;

  /// Artwork from the confirmed extension match, only for [Ext] sources.
  String? get extensionCover => _extensionCover;

  MediaStatus? _mediaListStatus;

  List<EpisodeDetails> _epLinks = [];
  Map<int, String> _simklEpisodeImages = {};
  int _episodeArtworkGeneration = 0;

  String? episodeThumbnail(EpisodeDetails episode) {
    if (episode.thumbnail != null && episode.thumbnail!.trim().isNotEmpty) {
      return episode.thumbnail;
    }
    return _simklEpisodeImages[episode.episodeNumber];
  }

  Future<void> _loadSimklEpisodeImages(
      List<EpisodeDetails> episodes, int generation, String sourceId) async {
    final simklId = _altDatabases
        .where((item) => item.database == Databases.simkl)
        .firstOrNull?.id;
    if (simklId == null || simklId <= 0) return;
    try {
      final results = await SimklEpisodeArtwork.instance.forEpisodes(simklId, episodes);
      if (generation != _episodeArtworkGeneration ||
          selectedSource.identifier != sourceId) return;
      _simklEpisodeImages = results;
      notifyListeners();
    } catch (_) {
      // SIMKL fallback must not break the extension's episode list.
    }
  }

  List<VideoStream> _streamSources = [];
  List<Map<String, String>> _qualities = [];
  List<List<Map<String, dynamic>>> _visibleEpList = [];
  List<AlternateDatabaseId> _altDatabases = [];

  int _currentPageIndex = 0;
  int _watched = 0;
  int _viewMode = 0;

  // Index of episode selected
  int? _selectedEpisodeToLoadStreams;

  Map? _lastWatchedDurationMap = {};

  bool _started = false;
  bool _epSearcherror = false;
  bool _loggedIn = false;
  bool _dataLoaded = false;
  bool _malExtrasLoading = false;
  bool get malExtrasLoading => _malExtrasLoading;
  int _malExtrasGeneration = 0;
  bool _infoPage = true;
  bool _infoLoadError = false;
  bool _preferDubs = false;
  bool _externalAssEnabled = false;
  bool get externalAssEnabled => _externalAssEnabled;
  Future<void> setExternalAssEnabled(bool enabled) async {
    _externalAssEnabled = enabled;
    notifyListeners();
    await ExternalAssPreferences.setEnabled(id, enabled);
  }

  // Getters
  bool get infoLoadError => _infoLoadError;
  bool get started => _started;
  bool get epSearcherror => _epSearcherror;
  bool get loggedIn => _loggedIn;
  bool get dataLoaded => _dataLoaded;
  bool get infoPage => _infoPage;
  bool get preferDubs => _preferDubs;

  Map? get lastWatchedDurationMap => _lastWatchedDurationMap;

  bool _episodeZeroWatched = false;
  int get watched => _watched;
  bool get episodeZeroWatched => _episodeZeroWatched;
  bool get hasEpisodeZero => _epLinks.any((ep) => ep.episodeNumber == 0 && ep.episodeLabel == 'Episode 0');
  Future<void> clearEpisodeZeroWatched() async {
    await LocalEpisodeZeroProgress.clearWatched(id);
    _episodeZeroWatched = false;
    notifyListeners();
  }
  int get nextEpisodeIndex => EpisodeProgress.nextIndex(_epLinks, _watched);
  EpisodeDetails? get nextEpisode => _epLinks.isEmpty ? null : _epLinks[nextEpisodeIndex];
  int get nextEpisodeResumeKey => _epLinks.isEmpty ? 1 : EpisodeProgress.resumeKey(_epLinks, nextEpisodeIndex);
  String get nextEpisodeLabel => nextEpisode == null ? 'Episode 1' : EpisodeProgress.label(nextEpisode!);
  bool episodeIsWatched(EpisodeDetails ep) =>
      ep.episodeNumber == 0 && ep.episodeLabel == 'Episode 0'
          ? _episodeZeroWatched
          : EpisodeProgress.isWatched(ep, _watched);
  int get viewMode => _viewMode;
  int get currentPageIndex => _currentPageIndex;
  int get viewModeIndexLength => 3;
  int? get selectedEpisodeToLoadStreams => _selectedEpisodeToLoadStreams;

  List<VideoStream> get streamSources => _streamSources;
  List<Map<String, String>> get qualities => _qualities;
  List<List<Map<String, dynamic>>> get visibleEpList => _visibleEpList;
  List<AlternateDatabaseId> get altDatabases => _altDatabases;
  List<EpisodeDetails> get epLinks => _epLinks;

  /// Current [MediaStatus] in the user's list
  MediaStatus? get mediaListStatus => _mediaListStatus;

  /// The name found from the search in the source
  String? get foundName => _foundName;

  /// Previously used server in the respective provider
  String? get previouslyUsedServer => _previouslyUsedServer;
  String? get previouslyUsedServerQuality => _previouslyUsedServerQuality;

  /// Currently selected source
  ProviderDetails get selectedSource => _selectedSource;

  /// The Anime info
  DatabaseInfo get data => _data;

  bool _initCalled = false;

  String? aspProvider;
  String? _previouslyUsedServer, _previouslyUsedServerQuality;

  set selectedSource(ProviderDetails val) {
    _selectedSource = val;
    _extensionCover = null;
    if (aspProvider != val.identifier) {
      saveAnimeSpecificPreference(
          id.toString(),
          AnimeSpecificPreference(
            preferredProvider: val.identifier,
          ));
    }
    // we just using this condition for validation (too lazy to add a field for it)
    sourceManager.useInbuiltProviders = selectedSource.version == "0.0.0.0";
    notifyListeners();
  }

  // set previouslyUsedServer(String? val) {
  //   if (_previouslyUsedServer == null && _previouslyUsedServer == val) return;
  //   _previouslyUsedServer = val;
  //   saveAnimeSpecificPreference(id.toString(), AnimeSpecificPreference(previouslyUsedServer: val)).then((v) {
  //     notifyListeners();
  //   });
  //   // notifyListeners();
  // }

  set viewMode(int newIndex) {
    _viewMode = newIndex;
    UserPreferences.saveUserPreferences(
      UserPreferencesModal(
        episodesViewMode: UserPreferencesModal.getViewModeEnum(newIndex),
      ),
    );
    notifyListeners();
  }

  set foundName(String? val) {
    _foundName = val;
    notifyListeners();
  }

  set epSearcherror(bool val) {
    _epSearcherror = val;
    notifyListeners();
  }

  set currentPageIndex(int val) {
    _currentPageIndex = val;
    notifyListeners();
  }

  set selectedEpisodeToLoadStreams(int? newIndex) {
    _selectedEpisodeToLoadStreams = newIndex;
    notifyListeners();
  }

  set preferDubs(bool val) {
    _preferDubs = val;
    UserPreferences.saveUserPreferences(
      UserPreferencesModal(
        preferDubs: val,
      ),
    );
    paginate(epLinks);
    notifyListeners();
  }

  /// Called in the init state
  void init() async {
    if (_initCalled) throw Exception("The initialization was already done");
    _initCalled = true;

    // Load manualsearch query and last watch
    final asp = await getAnimeSpecificPreference(id.toString());
    _externalAssEnabled = await ExternalAssPreferences.enabled(id);
    _lastWatchedDurationMap = asp?.lastWatchDuration ?? {};
    _episodeZeroWatched = await LocalEpisodeZeroProgress.isWatched(id);
    _manualSearchQuery = asp?.manualSearchQuery;
    _extensionSelections = Map<String, String>.from(asp?.extensionSelections ?? const {});

    aspProvider = asp?.preferredProvider;

    _previouslyUsedServer = asp?.previouslyUsedServer;

    // Set up sources.
    final sources = sourceManager.sources;
    final matchedSource = sources
        .where((e) => e.identifier == (asp?.preferredProvider ?? currentUserSettings?.preferredProvider))
        .firstOrNull; // pick provider from last selected provider or default one
    selectedSource =
        matchedSource != null ? matchedSource : (sources.isEmpty ? sourceManager.inbuiltSources[0] : sources[0]);

    await _getInfo(id);

    await loadPreferences();

    // load em concurrently (fixes the delay in loading the progress)
    getWatched();
    getEpisodes();
  }

  /// Fetch preferences
  Future<void> loadPreferences() async {
    final preferences = await UserPreferences.getUserPreferences();
    _viewMode = UserPreferencesModal.getViewModeIndex(preferences.episodesViewMode ?? EpisodeViewModes.tile);
    _preferDubs = preferences.preferDubs ?? false;

    //load TV stuff
    if (await isTv()) {
      // _watchInfoButtonFocusNode.requestFocus();
    }
    notifyListeners();
  }

  Future<void> updatePrevUsedServer(String? server, String? quality) async {
    if (server == null) return;
    _previouslyUsedServer = server;
    _previouslyUsedServerQuality = quality;
    await saveAnimeSpecificPreference(id.toString(), AnimeSpecificPreference(previouslyUsedServer: server,
    previouslyUsedServerQuality: quality,
    ));
    notifyListeners();
  }

  Future<void> getWatched({bool refreshLastWatchDuration = false}) async {
    try {
      if (await AniListLogin().isAnilistLoggedIn()) if (_mediaListStatus == null) {
        _watched = 0;
        _started = false;
      }
      final item = await getAnimeWatchProgress(id, _mediaListStatus);
      _watched = item == -1 ? 0 : item;
      _started = item != -1;

      final supposedPageIndex = nextEpisodeIndex ~/ 24; //index increases when the episodes are >24

      _currentPageIndex = supposedPageIndex >= visibleEpList.length ? visibleEpList.length - 1 : supposedPageIndex;

      if (refreshLastWatchDuration) {
        _episodeZeroWatched = await LocalEpisodeZeroProgress.isWatched(id);
        _lastWatchedDurationMap = (await getAnimeSpecificPreference(id.toString()))?.lastWatchDuration;
      }
    } catch (err) {
      floatingSnackBar("Couldn't fetch watch progress.");
      Logs.app.log(err.toString());
      if (currentUserSettings?.showErrors ?? false) {
        floatingSnackBar(err.toString(), waitForPreviousToFinish: true);
      }
    }

    notifyListeners();
  }

  Future<void> _getInfo(int id) async {
    final isFallback = AnimeMetadataRouter.instance.isFallbackId(id);
    final s = _altDatabases.toSet();
    final generation = ++_malExtrasGeneration;

    try {
      final info = await DatabaseHandler().getAnimeInfo(id);
      s.addAll(info.alternateDatabases);

      if (!isFallback && currentUserSettings?.database == Databases.anilist &&
          !(currentUserSettings?.disabledMetadataProviders ?? const <String>[])
              .contains('simkl') &&
          await AniListLogin().isAnilistLoggedIn()) {
        _loggedIn = true;

        try {
          final anilistUrl = "https://anilist.co/anime/$id";
          Logs.app.log(
            "[SIMKL LOOKUP SOURCE]: AniList -> SIMKL using $anilistUrl",
          );

          var res = await DatabaseHandler(database: Databases.simkl)
              .search(anilistUrl);

          Logs.app.log(
            "[SIMKL LOOKUP SOURCE]: AniList -> SIMKL results=${res.length}",
          );

          if (res.isEmpty) {
            final malId = info.alternateDatabases
                .where((entry) => entry.database == Databases.mal)
                .firstOrNull
                ?.id;

            if (malId == null) {
              Logs.app.log(
                "[SIMKL LOOKUP SOURCE]: MAL fallback skipped, no MAL ID available for AniList id=$id",
              );
            } else {
              final malUrl = "https://myanimelist.net/anime/$malId";
              Logs.app.log(
                "[SIMKL LOOKUP SOURCE]: AniList results=0 -> MAL fallback using $malUrl",
              );

              res = await DatabaseHandler(database: Databases.simkl)
                  .search(malUrl);

              Logs.app.log(
                "[SIMKL LOOKUP SOURCE]: MAL -> SIMKL results=${res.length}",
              );
            }
          }

          if (res.isNotEmpty) {
            final simklInfo = await DatabaseHandler(database: Databases.simkl)
                .getAnimeInfo(res[0].id);
            s.addAll(simklInfo.alternateDatabases);
            Logs.app.log(
              "[SIMKL LOOKUP SOURCE]: resolved simklId=${res[0].id}",
            );
          } else {
            Logs.app.log(
              "[SIMKL LOOKUP SOURCE]: no SIMKL match found after AniList/MAL lookup",
            );
          }
        } catch (err) {
          Logs.app.log(
            "[INFO] couldnt fetch simkl data. ${err.toString()}",
          );
          if (currentUserSettings?.showErrors ?? false) {
            floatingSnackBar("Couldnt fetch simkl data");
          }
        }
      }

      _altDatabases = s.toList();
      _dataLoaded = true;
      _data = info;
      _mediaListStatus = isFallback ? null : assignItemEnum(data.mediaListStatus);
      notifyListeners();
      if (isFallback && id < 0 && id > -1000000000) {
        _loadMalExtras((-id).toString(), generation);
      }
    } catch (err) {
      Logs.app.log(err.toString());
      if (currentUserSettings!.showErrors != null &&
          currentUserSettings!.showErrors!) {
        floatingSnackBar(err.toString());
      }
      _infoLoadError = true;
      notifyListeners();
      rethrow;
    }
  }

  /// Never block the series header/episodes waiting for third-party MAL extras.
  Future<void> _loadMalExtras(String malId, int generation) async {
    _malExtrasLoading = true;
    notifyListeners();
    try {
      final results = await Future.wait<dynamic>([
        MalAnimeMetadata.loadCharacters(malId),
        MalAnimeMetadata.loadRelatedFromJikan(malId),
      ]);
      if (generation != _malExtrasGeneration || !_dataLoaded) return;
      final characters = results[0] as List<Map<String, dynamic>>;
      final relations = results[1] as List<AnimeMetadataSummary>;
      final current = _data as AnilistInfo;
      final oldIds = current.related.map((item) => item.id).toSet();
      current.characters.addAll(characters);
      for (final relation in relations) {
        final relatedId = int.tryParse(relation.providerId);
        if (relatedId == null) continue;
        final localId = -relatedId;
        if (!oldIds.add(localId)) continue;
        current.related.add(AnilistAnimeRelatedRecommendation(
          cover: relation.cover,
          id: localId,
          rating: relation.rating,
          title: relation.title,
          type: relation.isManga ? 'MANGA' : 'ANIME',
          relationType: relation.relationType ?? 'Related',
        ));
      }
    } catch (err) {
      Logs.app.log('[MAL EXTRAS] optional data unavailable: $err');
    } finally {
      if (generation == _malExtrasGeneration) {
        _malExtrasLoading = false;
        notifyListeners();
      }
    }
  }

  // cleaned, refactored and pretty good ig
  void paginate(List<EpisodeDetails> links) {
    final generation = ++_episodeArtworkGeneration;
    final sourceId = selectedSource.identifier;
    _simklEpisodeImages = {};
    _epLinks = links;
    if (links.isNotEmpty && _altDatabases.any((it) => it.database == Databases.simkl)) {
      _loadSimklEpisodeImages(links, generation, sourceId);
    }
    _visibleEpList.clear();

    final filteredList = <Map<String, dynamic>>[];
    int? watchedProgressIndex; // js a variable to track the last watched episode in filtered list

    // filter the list if dubs are available and user needs dubs (works for subs too)
    for (int i = 0; i < _epLinks.length; i++) {
      final hasDub = links[i].hasDub ?? false;
      if (!_preferDubs || hasDub) {
        if (nextEpisodeIndex == i) watchedProgressIndex = filteredList.length;
        filteredList.add({'realIndex': i, 'epLink': links[i]});
      }
    }

    // Paginate to sections of 24 stuff
    for (int i = 0; i < filteredList.length; i += 24) {
      int end = (i + 24 < filteredList.length) ? i + 24 : filteredList.length;
      _visibleEpList.add(filteredList.sublist(i, end));
    }

    if (_visibleEpList.isEmpty) {
      // to avoid errors ofcourse
      _visibleEpList.add([]);
      _currentPageIndex = 0;
    } else {
      _currentPageIndex = watchedProgressIndex != null ? (watchedProgressIndex ~/ 24) : 0;
    }

    // _currentPageIndex = _currentPageIndex >= _visibleEpList.length ? _visibleEpList.length-1 : _currentPageIndex;
  }

  /// Prefer a previously confirmed link. A source slug must never be
  /// guessed from an AniList identifier or selected solely by result order.
  Future<void> _search(String query) async {
    final sourceId = selectedSource.identifier;
    if (AniyomiExtensionProvider.isExtensionId(sourceId)) {
      final saved = _extensionSelections[sourceId];
      if (saved != null && saved.isNotEmpty &&
          _attemptedSavedExtensionLinks.add(sourceId)) {
        _extensionLookupStage = 'saved_episode_link';
        try {
          final links = await sourceManager.getAnimeEpisodes(sourceId, saved);
          if (links.isNotEmpty) {
            paginate(links);
            _foundName = saved.split('\u001f').last;
            _extensionEpisodeDiagnostic = null;
            notifyListeners();
            return;
          }
        } catch (error) {
          // Do not print third-party exception text; URLs can contain tokens.
          Logs.app.log(
            'Saved extension episode link failed: ${error.runtimeType}');
        }
        // A stale source URL must never block trying fresh search results.
      }
    }

    _extensionLookupStage = 'source_search';
    final results = await sourceManager.searchInSource(sourceId, query);
    if (results.isEmpty) {
      throw StateError('No results from ${selectedSource.name}');
    }

    _extensionLookupStage = 'title_matching';
    Map<String, String?> selected;
    if (AniyomiExtensionProvider.isExtensionId(sourceId)) {
      // Only use exact title aliases from the current AniList series.
      // Ambiguous seasons/editions must be confirmed in Manual Search.
      final aliases = [
        data.title['english'],
        data.title['romaji'],
        data.title['native'],
      ].whereType<String>().map(ExtensionAniListMatcher.normalize)
          .where((title) => title.isNotEmpty).toSet();
      final exact = results.where((item) =>
          aliases.contains(ExtensionAniListMatcher.normalize(
              item['name'] ?? ''))).toList();
      if (exact.length == 1) {
        selected = exact.single;
      } else {
        // An English AniList title may differ completely from an extension's
        // Japanese/romaji title. Only accept an unambiguous score >= 95 which
        // independently resolves to this exact AniList media ID.
        final ranked = await ExtensionAniListMatcher.rank(
            query, results.map((item) => <String, dynamic>{
              'title': item['name'] ?? '',
              'url': item['alias'] ?? '',
              'cover': item['imageUrl'] ?? '',
            }).toList());
        final confirmed = ranked.where((item) =>
            item['anilistId'] == id &&
            (item['score'] as int? ?? 0) >= 95).toList();
        if (confirmed.length != 1) {
          throw StateError(
              'Aniyomi title is ambiguous; select it using Manual Search');
        }
        final alias = confirmed.single['url']?.toString();
        selected = results.firstWhere(
            (item) => item['alias'] == alias,
            orElse: () => <String, String?>{});
        if (selected.isEmpty) {
          throw StateError('Select the Aniyomi title using Manual Search');
        }
      }
    } else {
      final exact = results.where((item) => item['name'] == query).toList();
      selected = exact.isNotEmpty ? exact.first : results.first;
    }
    final alias = selected['alias'];
    if (alias == null || alias.isEmpty) throw StateError('Source URL not found');
    _extensionLookupStage = 'episode_fetch';
    final links = await sourceManager.getAnimeEpisodes(sourceId, alias);
    if (links.isEmpty) {
      throw StateError('No episodes for selected source result');
    }
    _extensionEpisodeDiagnostic = null;
    _extensionCover = AniyomiExtensionProvider.isExtensionId(sourceId)
        ? _validExtensionImage(selected['imageUrl']) : null;
    paginate(links);
    _foundName = selected['name'];
    notifyListeners();
  }

  /// Apply a user-confirmed search result consistently on desktop and TV.
  /// Persist the per-source match only after episodes have loaded.
  Future<void> applyManualSourceSelection(Map<String, String?> result) async {
    final sourceId = selectedSource.identifier;
    final alias = result['alias'];
    if (alias == null || alias.isEmpty) {
      throw StateError('Selected source result has no identifier');
    }
    final links = await sourceManager.getAnimeEpisodes(sourceId, alias);
    if (links.isEmpty) {
      throw StateError('No episodes for selected source result');
    }
    if (AniyomiExtensionProvider.isExtensionId(sourceId)) {
      await saveExtensionSourceSelection(result);
      _extensionCover = _validExtensionImage(result['imageUrl']);
    } else {
      _extensionCover = null;
    }
    paginate(links);
    _foundName = result['name'];
    notifyListeners();
  }

  String? _validExtensionImage(String? url) {
    final uri = Uri.tryParse(url?.trim() ?? '');
    if (uri == null || !uri.hasAuthority ||
        (uri.scheme != 'http' && uri.scheme != 'https')) return null;
    return uri.toString();
  }

  Future<void> saveExtensionSourceSelection(Map<String, String?> result) async {
    final sourceId = selectedSource.identifier;
    final alias = result['alias'];
    if (!AniyomiExtensionProvider.isExtensionId(sourceId) ||
        alias == null || alias.isEmpty) return;
    _extensionSelections[sourceId] = alias;
    await saveAnimeSpecificPreference(id.toString(),
        AnimeSpecificPreference(
            extensionSelections: {sourceId: alias}));
  }

  Future<void> getEpisodes() async {
    _foundName = null;
    _epSearcherror = false;
    _extensionEpisodeDiagnostic = null;
    _extensionLookupStage = null;
    _attemptedSavedExtensionLinks.clear();
    // Never display episodes from the previous provider while a new source loads.
    paginate([]);
    notifyListeners();

    if (AniyomiExtensionProvider.isExtensionId(selectedSource.identifier)) {
      // Extensions commonly index by Japanese/romaji titles rather than the
      // English AniList title. Try a bounded set of known names, but only
      // accept a unique, verified match. Never choose the first result.
      final titleVariants = <String?>[
        data.title['english'],
        data.title['romaji'],
        data.title['native'],
        ...data.synonyms.whereType<String>(),
      ];
      final titles = <String>[];
      final seenQueries = <String>{};
      void addQuery(String raw) {
        final cleaned = raw.trim();
        // Punctuation is significant for some source search APIs; keep both
        // the original title and a punctuation-free variant.
        if (cleaned.isNotEmpty && seenQueries.add(cleaned.toLowerCase())) {
          titles.add(cleaned);
        }
      }
      final seasonSuffix = RegExp(
        r'\s*(?:[-:–]\s*)?(?:season|part|cour)\s*\d+\s*' + r'$',
        caseSensitive: false,
      );
      final ordinalSeason = RegExp(
        r'\s*(?:2nd|3rd|4th|5th|6th)\s+season\s*' + r'$',
        caseSensitive: false,
      );
      for (final value in titleVariants) {
        if (value == null) continue;
        addQuery(value);
        final base = value
            .replaceAll(seasonSuffix, '')
            .replaceAll(ordinalSeason, '')
            .trim();
        addQuery(base);
        addQuery(base.replaceAll(
          RegExp(r'[^\p{L}\p{N}\s]+', unicode: true), ' ')
          .replaceAll(RegExp(r'\s+'), ' ').trim());
      }
      // Keep this bounded. A source may return unfiltered listings for some
      // searches; the _search method still verifies AniList identity/season.
      var attempts = 0;
      final failedStages = <String, int>{};
      String? lastErrorType;
      for (final title in titles) {
        if (attempts++ >= 16) break;
        try {
          await _search(title);
          if (_epLinks.isNotEmpty) {
            _extensionEpisodeDiagnostic = null;
            notifyListeners();
            return;
          }
        } catch (error) {
          final stage = _extensionLookupStage ?? 'unknown';
          failedStages[stage] = (failedStages[stage] ?? 0) + 1;
          lastErrorType = error.runtimeType.toString();
          Logs.app.log(
              'Aniyomi attempt $attempts failed at $stage: ${error.runtimeType}');
        }
      }
      final orderedStages = failedStages.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final summary = orderedStages.isNotEmpty
          ? orderedStages.map((e) => '${e.key}=${e.value}').join(', ')
          : 'no_matching_results';
      _extensionEpisodeDiagnostic =
          'No episodes after $attempts searches; stages: $summary; '
          'last error: ${lastErrorType ?? 'none'}. Use Manual Search.';
      // A missing catalog entry is not a network/decoder failure. The user
      // can still choose a result explicitly via the Manual Search sheet.
      _epSearcherror = true;
      Logs.app.log(
          'No verified AniList match for ${selectedSource.name} after $attempts title variants. Use Manual Search.');
      notifyListeners();
      return;
    }

    try {
      String searchTitle = data.title['english'] ?? data.title['romaji'] ?? '';
      if (_manualSearchQuery != null) {
        searchTitle = _manualSearchQuery!;
      }
      await _search(searchTitle);
      notifyListeners();
    } catch (err) {
      Logs.app.log(err.toString());

      final hasEnglishTitle = data.title['english'] != null;
      final didUseManualQuery = _manualSearchQuery != null;
      if (hasEnglishTitle && !didUseManualQuery) {
        try {
          await _search(data.title['romaji'] ?? '');
          notifyListeners();
          return;
        } catch (e) {
          Logs.app.log(e.toString());
        }
      }

      _epSearcherror = true;
      notifyListeners();
      if (currentUserSettings?.showErrors == true) {
        floatingSnackBar(err.toString());
      }
    }
  }

  void clearLastWatchDuration() async {
    _lastWatchedDurationMap = {};
    await saveAnimeSpecificPreference(
        id.toString(), AnimeSpecificPreference(lastWatchDuration: _lastWatchedDurationMap));
    notifyListeners();
  }

  static IconData getTrackerIcon(MediaStatus? mediaListStatus) {
    switch (mediaListStatus?.name) {
      case "CURRENT":
        return Icons.movie_outlined;
      case "PLANNING":
        return Icons.calendar_month_outlined;
      case "COMPLETED":
        return Icons.done_all_rounded;
      case "DROPPED":
        return Icons.close_rounded;
      default:
        return Icons.add_rounded;
    }
  }

  void refreshListStatus(String? status, int progress) {
    _mediaListStatus = assignItemEnum(status);
    _watched = progress;
    notifyListeners();
  }
}
