import 'package:flutter/material.dart';

import 'package:animestream/core/anime/providers/providerDetails.dart';
import 'package:animestream/core/anime/providers/aniyomiExtensionProvider.dart';
import 'package:animestream/core/anime/providers/extensionAniListMatcher.dart';
import 'package:animestream/core/anime/providers/models.dart';
import 'package:animestream/core/app/logging.dart';
import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/commons/enums.dart';
import 'package:animestream/core/commons/utils.dart';
import 'package:animestream/core/data/animeSpecificPreference.dart';
import 'package:animestream/core/data/preferences.dart';
import 'package:animestream/core/data/models.dart';
import 'package:animestream/core/data/watching.dart';
import 'package:animestream/core/database/database.dart';
import 'package:animestream/core/database/simkl/simkl.dart';
import 'package:animestream/core/database/handler/handler.dart';
import 'package:animestream/core/database/types.dart';
import 'package:animestream/ui/models/snackBar.dart';
import 'package:animestream/ui/models/sources.dart';

enum InfoView { info, watch }

class InfoProvider extends ChangeNotifier {
  final InfoView initialSection;
  int id;
  InfoProvider(int id, {this.initialSection = InfoView.info}) : this.id = id;

  late DatabaseInfo _data;

  final sourceManager = SourceManager.instance;

  // Will be set in _init()
  late ProviderDetails _selectedSource;

  String? _foundName;
  String? _manualSearchQuery;
  Map<String, String> _extensionSelections = {};

  MediaStatus? _mediaListStatus;

  List<EpisodeDetails> _epLinks = [];
  // List<VideoStream> _streamSources = [];
  // List<Map<String, String>> _qualities = [];
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
  bool _infoLoadError = false;
  bool _preferDubs = false;

  // Getters
  bool get infoLoadError => _infoLoadError;
  bool get started => _started;
  bool get epSearcherror => _epSearcherror;
  bool get loggedIn => _loggedIn;
  bool get dataLoaded => _dataLoaded;
  bool get preferDubs => _preferDubs;

  Map? get lastWatchedDurationMap => _lastWatchedDurationMap;

  int get watched => _watched;
  int get viewMode => _viewMode;
  int get currentPageIndex => _currentPageIndex;
  int get viewModeIndexLength => 3;
  int? get selectedEpisodeToLoadStreams => _selectedEpisodeToLoadStreams;

  // List<VideoStream> get streamSources => _streamSources;
  // List<Map<String, String>> get qualities => _qualities;
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
    if (aspProvider != val.identifier) {
      aspProvider = val.identifier;
      saveAnimeSpecificPreference(id.toString(), AnimeSpecificPreference(preferredProvider: val.identifier));
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
      UserPreferencesModal(episodesViewMode: UserPreferencesModal.getViewModeEnum(newIndex)),
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
    UserPreferences.saveUserPreferences(UserPreferencesModal(preferDubs: val));
    paginate(epLinks);
    notifyListeners();
  }

  set manualSearchQuery(String? query) {
    _manualSearchQuery = query;
    notifyListeners();
  }

  /// Called in the init state
  void init() async {
    if (_initCalled) return;
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
    selectedSource = matchedSource != null
        ? matchedSource
        : (sources.isEmpty ? sourceManager.inbuiltSources[0] : sources[0]);

    await _getInfo(id);

    if (_disposed) return;

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
    await saveAnimeSpecificPreference(
      id.toString(),
      AnimeSpecificPreference(previouslyUsedServer: server, previouslyUsedServerQuality: quality),
    );
    notifyListeners();
  }

  Future<void> getWatched({bool refreshLastWatchDuration = false}) async {
    try {
      // final isLoggedInAnilist = await AnilistLogin().isLoggedIn();

      final (watched, status) = await getAnimeWatchProgress(id);
      if (_disposed) return;

      _watched = watched;
      _started = watched > 0;
      _mediaListStatus = status;
      // } else {
      //   if (_mediaListStatus == null || data.progress == null) {
      //     _watched = 0;
      //     _started = false;
      //   } else {
      //     _watched = data.progress ?? 0;
      //     _started = true;
      //   }
      // }

      final supposedPageIndex = watched ~/ 25; //index increases when the episodes are >24

      _currentPageIndex = visibleEpList.isEmpty
          ? 0
          : (supposedPageIndex >= visibleEpList.length ? visibleEpList.length - 1 : supposedPageIndex);

      if (refreshLastWatchDuration) {
        try {
          _lastWatchedDurationMap = (await getAnimeSpecificPreference(id.toString()))?.lastWatchDuration;
        } catch (err) {
          Logs.app.log("failed to update last watch duration");
        }
      }
    } catch (err) {
      Logs.app.log("[WATCH PROGRESS] $err");
      if (currentUserSettings?.showErrors ?? false) {
        floatingSnackBar("Couldn't fetch watch progress: $err", waitForPreviousToFinish: true);
      }
    }

    notifyListeners();
  }

  Future<void> _getInfo(int id) async {
    try {
      _loggedIn = await DatabaseHandler().isLoggedIn();

      // Fetch anime details directly without waiting on auxiliary trackers
      final info = await DatabaseHandler().getAnimeInfo(id);
      final s = _altDatabases.toSet();
      s.addAll(info.alternateDatabases);
      _altDatabases = s.toList();
      _dataLoaded = true;
      _data = info;

      notifyListeners();

      // Resolve Simkl ID asynchronously
      final anilistId = currentUserSettings?.database == Databases.anilist
          ? id
          : _altDatabases.where((d) => d.database == Databases.anilist).firstOrNull?.id;
      final malId = currentUserSettings?.database == Databases.mal
          ? id
          : _altDatabases.where((d) => d.database == Databases.mal).firstOrNull?.id;
      _resolveSimklId(anilistId: anilistId, malId: malId);
    } catch (err) {
      Logs.app.log(err.toString());
      if (currentUserSettings?.showErrors ?? false) floatingSnackBar(err.toString());
      _infoLoadError = true;
      notifyListeners();
    }
  }

  void _resolveSimklId({int? anilistId, int? malId}) async {
    try {
      if (_altDatabases.any((db) => db.database == Databases.simkl)) return;

      final simkl = Simkl();
      var simklId = await simkl.getIdFromRedirect(anilistId: anilistId, malId: malId);
      if (simklId == null && anilistId != null && malId != null) {
        simklId = await simkl.getIdFromRedirect(malId: malId);
      }
      if (_disposed) return;
      if (simklId != null) {
        final s = _altDatabases.toSet();
        s.add(AlternateDatabaseId(database: Databases.simkl, id: simklId));
        _altDatabases = s.toList();
        notifyListeners();
      }
    } catch (err) {
      Logs.app.log("[INFO] couldn't resolve simkl id: $err");
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
    paginate(links);
    _foundName = selected['name'];
    notifyListeners();
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
    } catch (err) {
      Logs.app.log(err.toString());

      final hasEnglishTitle = data.title['english'] != null;
      final didUseManualQuery = _manualSearchQuery != null;

      final romajiTitle = data.title['romaji'];
      if (hasEnglishTitle && !didUseManualQuery && romajiTitle != null && romajiTitle != data.title['english']) {
        // try once more with romaji title if english title failed and romaji is different
        try {
          await _search(romajiTitle);
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
      id.toString(),
      AnimeSpecificPreference(lastWatchDuration: _lastWatchedDurationMap),
    );
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
      case "PAUSED":
        return Icons.pause_circle_outline_rounded;
      default:
        return Icons.add_rounded;
    }
  }

  void refreshListStatus(String? status, int progress) {
    _mediaListStatus = assignItemEnum(status);
    _watched = progress;
    _started = progress > 0;

    // recalculate the page index based on updated value
    paginate(epLinks);
    notifyListeners();
  }

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }
}
