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
  String? _extensionCover;

  /// Artwork from the confirmed extension match, only for [Ext] sources.
  String? get extensionCover => _extensionCover;

  MediaStatus? _mediaListStatus;

  List<EpisodeDetails> _epLinks = [];
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
  bool _infoPage = true;
  bool _infoLoadError = false;
  bool _preferDubs = false;

  // Getters
  bool get infoLoadError => _infoLoadError;
  bool get started => _started;
  bool get epSearcherror => _epSearcherror;
  bool get loggedIn => _loggedIn;
  bool get dataLoaded => _dataLoaded;
  bool get infoPage => _infoPage;
  bool get preferDubs => _preferDubs;

  Map? get lastWatchedDurationMap => _lastWatchedDurationMap;

  int get watched => _watched;
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
    _lastWatchedDurationMap = asp?.lastWatchDuration ?? {};
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

      final supposedPageIndex = watched ~/ 25; //index increases when the episodes are >24

      _currentPageIndex = supposedPageIndex >= visibleEpList.length ? visibleEpList.length - 1 : supposedPageIndex;

      if (refreshLastWatchDuration) {
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
    final s = _altDatabases.toSet();

    try {
      final info = await DatabaseHandler().getAnimeInfo(id);
      s.addAll(info.alternateDatabases);

      if (currentUserSettings?.database == Databases.anilist &&
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
      _mediaListStatus = assignItemEnum(data.mediaListStatus);
      notifyListeners();
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

  // cleaned, refactored and pretty good ig
  void paginate(List<EpisodeDetails> links) {
    _epLinks = links;
    _visibleEpList.clear();

    final filteredList = <Map<String, dynamic>>[];
    int? watchedProgressIndex; // js a variable to track the last watched episode in filtered list

    // filter the list if dubs are available and user needs dubs (works for subs too)
    for (int i = 0; i < _epLinks.length; i++) {
      final hasDub = links[i].hasDub ?? false;
      if (!_preferDubs || hasDub) {
        if (watched == i) watchedProgressIndex = filteredList.length;
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
      if (saved != null && saved.isNotEmpty) {
        final links = await sourceManager.getAnimeEpisodes(sourceId, saved);
        if (links.isNotEmpty) {
          paginate(links);
          _foundName = saved.split('\u001f').last;
          notifyListeners();
          return;
        }
      }
    }

    final results = await sourceManager.searchInSource(sourceId, query);
    if (results.isEmpty) {
      throw StateError('No results from ${selectedSource.name}');
    }

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
    final links = await sourceManager.getAnimeEpisodes(sourceId, alias);
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
      for (final title in titles) {
        if (attempts++ >= 16) break;
        try {
          await _search(title);
          if (_epLinks.isNotEmpty) {
            notifyListeners();
            return;
          }
        } catch (error) {
          Logs.app.log(
              'Aniyomi source search attempt $attempts failed: ${error.runtimeType}');
        }
      }
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
