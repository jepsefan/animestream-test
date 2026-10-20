import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:animestream/core/anime/providers/types.dart';
import 'package:animestream/core/anime/providers/externalAssPreferences.dart';
import 'package:animestream/core/app/logging.dart';
import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/commons/extractQuality.dart';
import 'package:animestream/core/commons/utils.dart';
import 'package:animestream/core/data/preferences.dart';
import 'package:animestream/core/database/aniskip/aniskip.dart';
import 'package:animestream/core/database/database.dart';
import 'package:animestream/core/database/types.dart';
import 'package:animestream/core/integrations/discord/desktopRPC.dart';
import 'package:animestream/ui/models/sources.dart';
import 'package:animestream/ui/models/widgets/subtitles/subtitleSettings.dart';
import 'package:dart_discord_presence/dart_discord_presence.dart';
import 'package:flutter/material.dart';

/// Handle the state of player. manages datas like quality, servers etc..
class PlayerDataProvider extends ChangeNotifier {
  PlayerDataProviderState _state;
  List<EpisodeDetails> epLinks;
  String showTitle; // Title of the anime
  String? coverImageUrl;
  int showId; // Id of the anime
  String selectedSource;
  int startIndex; // Index of episode to start from
  List<AlternateDatabaseId> altDatabases;
  double? lastWatchDuration;
  bool preferDubs;

  PlayerDataProvider({
    required List<VideoStream> initialStreams,
    required VideoStream initialStream,
    required this.epLinks,
    required this.showTitle,
    required this.selectedSource,
    required this.showId,
    required this.startIndex,
    required this.altDatabases,
    required this.lastWatchDuration,
    this.coverImageUrl, // just for presence updation
    this.preferDubs = false,
  }) : _state = PlayerDataProviderState(
          streams: initialStreams,
          currentStream: initialStream,
          controlsLocked: false,
          qualities: [],
          currentQuality: QualityStream.paceholder(),
          audioTracks: [],
          currentAudioTrack: AudioStream.placeholder(),
          currentEpIndex: startIndex,
          preloadStarted: false,
          preloadedSources: [],
          currentTimeStamp: '00:00',
          maxTimeStamp: '00:00',
          preferredServer: selectedSource,
          sliderValue: 0,
        );

  ExternalSubtitleTrack? _crossSourceAss;
  bool _crossSourceLoading = false;
  bool _externalAssEnabled = false;
  int _crossSourceGeneration = 0;
  bool get externalAssEnabled => _externalAssEnabled;
  String? crossSourceError;
  String? _crossSourceSlot;
  Map<String, String>? crossSourceHeaders;
  bool get crossSourceLoading => _crossSourceLoading;
  bool get hasCrossSourceAss => _crossSourceAss != null;
  int _externalAssDelayMs = 0;
  int get externalAssDelayMs => _externalAssDelayMs;
  bool _editingExternalAssDelay = false;
  bool get editingExternalAssDelay => _editingExternalAssDelay;

  Future<void> loadExternalAssDelay() async {
    _externalAssDelayMs = await ExternalAssPreferences.delayMs(showId);
    notifyListeners();
  }

  Future<void> setExternalAssDelayMs(int value) async {
    _externalAssDelayMs = ((value / 50).round() * 50).clamp(-30000, 30000).toInt();
    notifyListeners();
    await ExternalAssPreferences.setDelayMs(showId, _externalAssDelayMs);
  }

  void beginExternalAssDelayEdit() {
    if (!hasCrossSourceAss) return;
    _editingExternalAssDelay = true;
    notifyListeners();
  }

  void finishExternalAssDelayEdit() {
    if (!_editingExternalAssDelay) return;
    _editingExternalAssDelay = false;
    notifyListeners();
  }


  Future<void> loadCrossSourceAss({String? selectedSlot}) async {
    final generation = ++_crossSourceGeneration;
    final episodeNumber = epLinks[_state.currentEpIndex].episodeNumber;
    _crossSourceLoading = true;
    _crossSourceAss = null;
    _editingExternalAssDelay = false;
    crossSourceError = null;
    notifyListeners();
    try {
      final enabled = await ExternalAssPreferences.enabled(showId);
      if (generation != _crossSourceGeneration) return;
      _externalAssEnabled = enabled;
      if (!enabled) return;
      final slot = selectedSlot ?? await ExternalAssPreferences.lastUsed(showId);
      final sourceId = slot == 'secondary'
          ? await ExternalAssPreferences.secondary()
          : await ExternalAssPreferences.primary();
      if (sourceId.isEmpty) {
        crossSourceError = 'Select an ASS extension in Player Settings';
        return;
      }
      final track = await ExternalAssLookup.find(
          sourceId: sourceId, animeId: showId, title: showTitle,
          episodeNumber: episodeNumber,
          language: await ExternalAssPreferences.language());
      if (generation != _crossSourceGeneration ||
          epLinks[_state.currentEpIndex].episodeNumber != episodeNumber) return;
      if (track == null) {
        crossSourceError = 'No unambiguous ASS match for this episode';
        return;
      }
      _crossSourceAss = track.track;
      crossSourceHeaders = track.headers;
      await inspectSubtitleTrack(track.track);
      if (subtitleFormatFor(track.track) != 'ass') {
        _crossSourceAss = null;
        crossSourceError = 'External subtitle is not a verified ASS file';
        return;
      }
      if (generation != _crossSourceGeneration) return;
      _crossSourceSlot = slot;
      await ExternalAssPreferences.setLastUsed(showId, slot);
    } catch (error) {
      if (generation != _crossSourceGeneration) return;
      _crossSourceAss = null;
      crossSourceError = 'External ASS lookup failed: ${error.runtimeType}';
    } finally {
      if (generation == _crossSourceGeneration) {
        _crossSourceLoading = false;
        notifyListeners();
      }
    }
  }

  // Keep track preference for this playback session. Rebind by language when
  // the player switches server or episode (URLs are not interchangeable).
  String? _preferredSubtitleLanguage;
  String? _selectedSubtitleUrl;
  String? _selectedSubtitleStreamUrl;

  // Subtitle URLs in some Aniyomi sources have opaque IDs or no extension.
  // Identify format from the actual bytes, never infer ASS from an empty hint.
  final Map<String, String> _detectedSubtitleFormats = {};
  final Set<String> _probingSubtitleUrls = {};

  String subtitleFormatFor(ExternalSubtitleTrack track) =>
      track.format.isNotEmpty
          ? track.format.toLowerCase()
          : (_detectedSubtitleFormats[track.url] ?? '');

  String subtitleFormatLabel(ExternalSubtitleTrack track) {
    final value = subtitleFormatFor(track);
    return value.isEmpty ? 'Detecting / unknown' : value.toUpperCase();
  }

  static String identifySubtitleContent(String sample) {
    final content = sample.trimLeft().replaceFirst('\uFEFF', '');
    if (content.startsWith('WEBVTT')) return 'vtt';
    if (RegExp(r'^\[Script Info\]', caseSensitive: false, multiLine: true)
        .hasMatch(content) ||
        (content.contains('[Events]') && content.contains('Dialogue:'))) {
      return 'ass';
    }
    if (RegExp(r'^\s*\d+\s*\r?\n\s*\d{2}:\d{2}:\d{2}[,.]\d{3}\s*-->',
            multiLine: true).hasMatch(content) ||
        RegExp(r'\d{2}:\d{2}:\d{2},\d{3}\s*-->').hasMatch(content)) {
      return 'srt';
    }
    return '';
  }

  Future<void> inspectSubtitleTrack(ExternalSubtitleTrack track) async {
    if (track.format.isNotEmpty ||
        _detectedSubtitleFormats.containsKey(track.url) ||
        !_probingSubtitleUrls.add(track.url)) return;
    final uri = Uri.tryParse(track.url);
    if (uri == null || !['http', 'https'].contains(uri.scheme) ||
        uri.host.isEmpty) {
      _probingSubtitleUrls.remove(track.url);
      return;
    }
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    try {
      final request = await client.getUrl(uri).timeout(const Duration(seconds: 10));
      request.headers.set(HttpHeaders.rangeHeader, 'bytes=0-8191');
      for (final entry in (track.url == _crossSourceAss?.url
          ? (crossSourceHeaders ?? const <String, String>{})
          : (_state.currentStream.customHeaders ?? const <String, String>{})).entries) {
        // Request-specific headers may be necessary for extension subtitles.
        if (entry.key.toLowerCase() != 'range') {
          request.headers.set(entry.key, entry.value);
        }
      }
      final response = await request.close().timeout(const Duration(seconds: 10));
      if (response.statusCode != 200 && response.statusCode != 206) {
        throw HttpException('Subtitle HTTP status ${response.statusCode}');
      }
      final bytes = <int>[];
      await for (final chunk in response.timeout(const Duration(seconds: 10))) {
        final remaining = 8192 - bytes.length;
        if (remaining <= 0) break;
        bytes.addAll(chunk.take(remaining));
        if (bytes.length >= 8192) break;
      }
      final format = identifySubtitleContent(
          utf8.decode(bytes, allowMalformed: true));
      if (format.isNotEmpty) {
        _detectedSubtitleFormats[track.url] = format;
      } else {
        _detectedSubtitleFormats[track.url] = '';
      }
      notifyListeners();
    } catch (error) {
      // Signed subtitle URLs and request headers must never be logged.
      Logs.player.log('Subtitle format inspection failed: ${error.runtimeType}');
      _detectedSubtitleFormats[track.url] = '';
      notifyListeners();
    } finally {
      client.close(force: true);
      _probingSubtitleUrls.remove(track.url);
    }
  }

  Future<void> inspectAvailableSubtitleTracks() async {
    final selected = selectedSubtitleTrack;
    if (selected != null) await inspectSubtitleTrack(selected);
  }

  Future<void> inspectRemainingSubtitleTracks() async {
    // Populate format labels in the open menu without blocking video startup.
    // Sequential requests avoid overloading the extension's subtitle host.
    final selectedUrl = selectedSubtitleTrack?.url;
    for (final track in availableSubtitleTracks) {
      if (track.url == selectedUrl) continue;
      await inspectSubtitleTrack(track);
    }
  }


  List<ExternalSubtitleTrack> get availableSubtitleTracks {
    if (_crossSourceAss != null) return [_crossSourceAss!, ..._nativeSubtitleTracks];
    return _nativeSubtitleTracks;
  }

  List<ExternalSubtitleTrack> get _nativeSubtitleTracks {
    final stream = _state.currentStream;
    if (stream.subtitleTracks.isNotEmpty) return stream.subtitleTracks;
    final url = stream.subtitle;
    if (url == null || url.isEmpty) return const [];
    return [
      ExternalSubtitleTrack(
        url: url,
        language: 'Default',
        label: 'Default',
        format: stream.subtitleFormat ?? '',
      )
    ];
  }

  ExternalSubtitleTrack? get selectedSubtitleTrack {
    final tracks = availableSubtitleTracks;
    if (tracks.isEmpty) return null;
    if (_crossSourceAss != null) return _crossSourceAss;
    if (_selectedSubtitleStreamUrl == _state.currentStream.url &&
        _selectedSubtitleUrl != null) {
      for (final track in tracks) {
        if (track.url == _selectedSubtitleUrl) return track;
      }
    }
    if (_preferredSubtitleLanguage != null) {
      for (final track in tracks) {
        if (track.language.toLowerCase() ==
            _preferredSubtitleLanguage!.toLowerCase()) return track;
      }
    }
    return tracks.first;
  }

  Future<void> selectSubtitleTrack(ExternalSubtitleTrack track) async {
    if (!availableSubtitleTracks.any((item) => item.url == track.url)) return;
    if (_crossSourceAss != null && track.url != _crossSourceAss!.url) {
      _crossSourceAss = null;
      _editingExternalAssDelay = false;
    }
    _selectedSubtitleStreamUrl = _state.currentStream.url;
    _selectedSubtitleUrl = track.url;
    _preferredSubtitleLanguage = track.language;
    notifyListeners();
    await inspectSubtitleTrack(track);
  }

  PlayerDataProviderState get state => _state;

  final discord = (currentUserSettings?.enableDiscordRichPresence ?? false) ? DiscordDesktopRPC() : null;

  late SubtitleSettings subtitleSettings;

  /// Call this to refresh/init subs settings
  void initSubsettings() => UserPreferences.getUserPreferences().then((val) {
        subtitleSettings = val.subtitleSettings ?? SubtitleSettings();
        _state = _state.copyWith(subsInited: true);
        notifyListeners();
      });

  /// Exposed HLS renditions from the extension when the URL is a local
  /// proxy without a .m3u8 path. Names are metadata until BetterPlayer's
  /// native rendition selector confirms the tracks.
  List<AudioStream> get availableAudioTracks {
    final native = _state.audioTracks;
    if (native.isNotEmpty) return native;
    if (_state.currentStream.externalAudioTracks.isEmpty) return const [];
    return _state.currentStream.externalAudioTracks.map((t) => AudioStream(
      url: t.url,
      language: t.language,
      name: t.label.isEmpty ? t.language : t.label,
      channels: '',
      groupId: 'ext-audio',
    )).toList();
  }

  /// Get and store the qualities and audio available for the current stream
  Future<void> extractCurrentStreamQualities() async {
    final url = _state.currentStream.url;
    final headers = _state.currentStream.customHeaders;
    // DASH is an MPEG-DASH manifest, not an HLS master playlist. Leave it
    // intact for Android ExoPlayer instead of parsing it as an HLS file.
    final path = Uri.tryParse(url)?.path.toLowerCase() ?? '';
    if (path.endsWith('.mpd') || path.endsWith('.dash')) {
      _state = _state.copyWith(
        qualities: [QualityStream(
          url: url, resolution: 'default',
          quality: _state.currentStream.quality,
        )],
        audioTracks: <AudioStream>[],
      );
      notifyListeners();
      return;
    }
    try {
      final master = await parseMasterPlaylist(url, customHeader: headers);
      _state = _state.copyWith(qualities: master.qualityStreams, audioTracks: master.audioStreams);
    } catch (e) {
      // just a backup, the code shouldnt reach here, but my luck... brooo....
      _state = _state.copyWith(
        qualities: [QualityStream(url: url, resolution: 'default', quality: _state.currentStream.quality)],
      );
    }
    notifyListeners();
    print("Available Qualities: ${state.qualities}");
  }

  /// Selects the preferred quality stream from available qualities, if it exists. Just a small helper
  QualityStream getPreferredQualityStreamFromQualities() {
    return _state.qualities
            .where((it) => it.quality == (currentUserSettings?.preferredQuality ?? '720p'))
            .firstOrNull ??
        _state.qualities[0];
  }

  /// Update the state of current quality
  void updateCurrentQuality(QualityStream quality) {
    _state = _state.copyWith(currentQuality: quality);
    notifyListeners();
  }

  /// Update the current audio track!
  void updateCurrentAudioTrack(AudioStream track) {
    _state = _state.copyWith(currentAudioTrack: track);
    notifyListeners();
  }

  /// Update the state of streams
  void updateStreams(List<VideoStream> streams) {
    _state = _state.copyWith(streams: streams);
    notifyListeners();
  }

  /// Update the state of current stream
  void updateCurrentStream(VideoStream stream) {
    _state = _state.copyWith(currentStream: stream);
    notifyListeners();
  }

  /// Update the state of preloaded sources
  void updatePreloadSources(List<VideoStream> sources) {
    _state = _state.copyWith(preloadedSources: sources);
    notifyListeners();
  }

  /// Update the state of currentEpIndex
  void updateCurrentEpIndex(int newIndex) {
    _state = _state.copyWith(currentEpIndex: newIndex, preloadStarted: false, preloadedSources: []);
    if (discord != null) updatePresence();
    notifyListeners();
  }

  /// Toggle control lock
  void toggleControlsLock() {
    _state = _state.copyWith(controlsLocked: !_state.controlsLocked);
    notifyListeners();
  }

  /// Update the state of time stamps
  void updateTimeStamps(String current, String max) {
    _state = _state.copyWith(
      currentTimeStamp: current,
      maxTimeStamp: max,
    );
    notifyListeners();
  }

  /// Update slider value
  void updateSliderValue(int val) {
    _state = _state.copyWith(sliderValue: val);
    notifyListeners();
  }

  /// Load the sources for streaming of next episode
  void preloadNextEpisode() async {
    // Just return if its the last episode!
    if (_state.currentEpIndex + 1 >= epLinks.length) {
      _state = _state.copyWith(
        preloadStarted: true, // setting to true to avoid unwanted repeated calls
      );
      return;
    }

    _state = _state.copyWith(preloadStarted: true, preloadedSources: []);

    final index = _state.currentEpIndex + 1 == epLinks.length ? null : _state.currentEpIndex + 1;
    if (index == null) {
      print("On the final episode. No preloads available");
      return;
    }
    List<VideoStream> srcs = [];
    //its actually the getStreams function!
    await SourceManager.instance.getStreams(selectedSource, epLinks[index].episodeLink,
        dub: preferDubs, metadata: epLinks[index].metadata, (list, finished) {
      srcs = srcs + list;
      if (finished) {
        _state = _state.copyWith(preloadedSources: srcs);
        print("[PLAYER] PRELOAD FINISHED FOUND ${srcs.length} SERVERS");
      }
    });
  }

  /// Get skip times for current episode
  Future<void> getSkipTimesForCurrentEpisode({double videoDuration = 0}) async {
    final malId = altDatabases.where((element) => element.database == Databases.mal).firstOrNull?.id;
    if (malId == null) {
      Logs.player.log("No MAL id found for skip times");
      return;
    }
    final episodeNumber = epLinks[_state.currentEpIndex].episodeNumber;
    final skipTimes = await AniSkip().getSkipTimes(malId, episodeNumber, episodeLength: videoDuration / 1000);
    // print(skipTimes);
    if (skipTimes == null) {
      Logs.player.log("No skip times found");
      return;
    }

    _state = _state.copyWith(opSkip: skipTimes.op, edSkip: skipTimes.ed);
  }

  Future<void> startRPC() async {
    await discord?.initiateConnection();
  }

  Future<void> updatePresence() async {
    await discord?.updatePresence(
      DiscordPresence(
        type: DiscordActivityType.watching,
        details: "$showTitle",
        statusDisplayType: DiscordStatusDisplayType.details,
        state: "Episode ${_state.currentEpIndex + 1}",
        largeAsset: DiscordAsset.fromUrl(coverImageUrl),
        smallAsset: DiscordAsset.fromKey("app_icon"),
        timestamps: DiscordTimestamps(start: DateTime.now().millisecondsSinceEpoch ~/ 1000),
      ),
    );
  }

  Future<void> stopRPC() async {
    await discord?.dispose();
  }

  /// Update subtitle settings
  void updateSubtitleSettings(SubtitleSettings settings) {
    subtitleSettings = settings;
  }

  /// Update any value from state
  void update(PlayerDataProviderState newState) {
    _state = newState;
    notifyListeners();
  }
}

class PlayerDataProviderState {
  /// All available streams for the episode
  final List<VideoStream> streams;

  /// Currently playing stream
  final VideoStream currentStream;

  /// Control's lock state
  final bool controlsLocked;

  /// Available qualities for current stream
  final List<QualityStream> qualities;

  /// Currently selected quality
  final QualityStream currentQuality;

  /// Available audio tracks
  final List<AudioStream> audioTracks;

  /// Currently playing audio track
  final AudioStream currentAudioTrack;

  /// Current episode index (obviously)
  final int currentEpIndex;

  /// The flag to check if the preload has started
  final bool preloadStarted;

  /// Preloaded sources for next episode
  final List<VideoStream> preloadedSources;

  /// Guess what?! Current time stamp
  final String currentTimeStamp;

  /// yes.. the duration of the video as timestamp
  final String maxTimeStamp;

  /// Preferred server for streaming
  final String preferredServer;

  /// The value for the player progress slider
  final int sliderValue;

  /// Whether subtitle settings have been inited
  final bool subsInited;

  /// Opening skip interval
  final SkipInterval? opSkip;

  /// Ending skip interval
  final SkipInterval? edSkip;

  PlayerDataProviderState({
    required this.streams,
    required this.currentStream,
    required this.controlsLocked,
    required this.qualities,
    required this.currentQuality,
    required this.currentEpIndex,
    required this.preloadStarted,
    required this.preloadedSources,
    required this.currentTimeStamp,
    required this.maxTimeStamp,
    required this.preferredServer,
    required this.sliderValue,
    required this.audioTracks,
    required this.currentAudioTrack,
    this.subsInited = false,
    this.opSkip = null,
    this.edSkip = null,
  });

  PlayerDataProviderState copyWith({
    List<VideoStream>? streams,
    VideoStream? currentStream,
    bool? controlsLocked,
    bool? controlsVisible,
    bool? wakelockEnabled,
    List<QualityStream>? qualities,
    QualityStream? currentQuality,
    int? currentEpIndex,
    bool? preloadStarted,
    List<VideoStream>? preloadedSources,
    String? currentTimeStamp,
    String? maxTimeStamp,
    String? preferredServer,
    int? sliderValue,
    bool? subsInited,
    List<AudioStream>? audioTracks,
    AudioStream? currentAudioTrack,
    SkipInterval? opSkip,
    SkipInterval? edSkip,
  }) {
    return PlayerDataProviderState(
      streams: streams ?? this.streams,
      currentStream: currentStream ?? this.currentStream,
      controlsLocked: controlsLocked ?? this.controlsLocked,
      qualities: qualities ?? this.qualities,
      currentQuality: currentQuality ?? this.currentQuality,
      currentEpIndex: currentEpIndex ?? this.currentEpIndex,
      preloadStarted: preloadStarted ?? this.preloadStarted,
      preloadedSources: preloadedSources ?? this.preloadedSources,
      currentTimeStamp: currentTimeStamp ?? this.currentTimeStamp,
      maxTimeStamp: maxTimeStamp ?? this.maxTimeStamp,
      preferredServer: preferredServer ?? this.preferredServer,
      sliderValue: sliderValue ?? this.sliderValue,
      subsInited: subsInited ?? this.subsInited,
      audioTracks: audioTracks ?? this.audioTracks,
      currentAudioTrack: currentAudioTrack ?? this.currentAudioTrack,
      opSkip: opSkip ?? this.opSkip,
      edSkip: edSkip ?? this.edSkip,
    );
  }
}

class ViewMode {
  final IconData icon;
  final String desc;
  final BoxFit value;

  ViewMode({required this.icon, required this.desc, required this.value});

  static ViewMode get fit => viewModes[0];

  static ViewMode get filled => viewModes[1];

  static ViewMode get cropped => viewModes[2];
}

final List<ViewMode> viewModes = [
  ViewMode(
    icon: Icons.fullscreen,
    desc: "fit",
    value: BoxFit.contain,
  ),
  ViewMode(
    icon: Icons.zoom_out_map_rounded,
    desc: "filled",
    value: BoxFit.fill,
  ),
  ViewMode(
    icon: Icons.crop_outlined,
    desc: "cropped",
    value: BoxFit.cover,
  ),
];
