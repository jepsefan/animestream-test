import 'dart:io';
import 'package:hive/hive.dart';
import 'package:animestream/core/anime/providers/aniyomiExtensionBridge.dart';
import 'package:animestream/core/anime/providers/aniyomiExtensionProvider.dart';
import 'package:animestream/core/anime/providers/anikoto.dart';
import 'package:animestream/core/anime/providers/animegg.dart';
import 'package:animestream/core/anime/providers/animeonsen.dart';
import 'package:animestream/core/anime/providers/animepahe.dart';
import 'package:animestream/core/anime/providers/anizone.dart';
import 'package:animestream/core/anime/providers/gojo.dart';
import 'package:animestream/core/anime/providers/animeProvider.dart';
import 'package:animestream/core/anime/providers/providerDetails.dart';
import 'package:animestream/core/anime/providers/providerManager.dart';
import 'package:animestream/core/anime/providers/providerPlugin.dart';
import 'package:animestream/core/anime/providers/types.dart';
import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:flutter/material.dart';

/// This Singleton manages all the sources/providers
/// Contains the list of sources and methods to interact with them
class SourceManager {
  SourceManager._();

  static final SourceManager instance = SourceManager._();

  static final _undownloadableSources = [
    //uses mpd which needs ffmpeg to download (makes the app bulky :< )
    "animeonsen", "anizone"
  ];

  final List<ProviderDetails> inbuiltSources = [
    "AnimeOnsen",
    "AniZone",
    "Anikoto",
    "Animegg",
  ]
      .map((e) => ProviderDetails(
          name: e,
          identifier: e.toLowerCase() + "_inbuilt",
          version: "0.0.0.0",
          supportDownloads: !_undownloadableSources.contains(e.toLowerCase())))
      .toList();

  /// Used till complete migration to remote providers is complete.
  bool _useInbuiltProviders = true;

  bool get useInbuiltProviders => _useInbuiltProviders;

  set useInbuiltProviders(bool val) => _useInbuiltProviders = val;

  final List<ProviderDetails> _sources = [];

  final ProviderPlugin _plugin = ProviderPlugin();
  final Map<String, AniyomiExtensionProvider> _aniyomi = {};
  static const _approvedStore = 'aniyomi_installed_source_approvals_v3';
  final Map<String, List<AniyomiExtensionSourceInfo>> _approvedSources = {};

  /// Identity verified against installed APK signer/version on restoration.
  /// Used only for user-triggered Source settings relinking after restart.
  AniyomiExtensionSourceInfo? approvedExtensionSource(
      String packageName, int sourceId) {
    for (final source in
        _approvedSources[packageName] ?? const <AniyomiExtensionSourceInfo>[]) {
      if (source.id == sourceId) return source;
    }
    return null;
  }

  String? _apkSignature(AniyomiExtensionInfo ext) {
    final values = ext.signingFingerprints.map((s) => s.toLowerCase()).toList()..sort();
    if (values.isEmpty ||
        values.any((s) => !RegExp(r'^[a-f0-9]{64}$').hasMatch(s))) return null;
    return values.join(':');
  }

  Future<void> enableExtensionSources(AniyomiExtensionInfo ext) async {
    final signature = _apkSignature(ext);
    if (signature == null) {
      throw StateError('Cannot approve an extension without a valid APK signing key');
    }
    final sources = await AniyomiExtensionBridge.discoverSources(ext.packageName);
    if (sources.isEmpty) throw StateError('No sources found in this extension');
    final now = await AniyomiExtensionBridge.listInstalledExtensions();
    final current = now.where((e) => e.packageName == ext.packageName).firstOrNull;
    if (current == null || current.versionCode != ext.versionCode ||
        _apkSignature(current) != signature) {
      throw StateError('Extension changed during approval; refresh and retry');
    }
    final box = await Hive.openBox(_approvedStore);
    await box.put(ext.packageName, {
      'signingKey': signature,
      'versionCode': ext.versionCode,
      'sources': sources.map((s) => {
        'id': s.id, 'name': s.name, 'language': s.language,
      }).toList(),
    });
    _approvedSources[ext.packageName] = sources;
    await refreshAniyomiExtensions();
  }

  Future<void> disableExtensionSources(String packageName) async {
    final box = await Hive.openBox(_approvedStore);
    await box.delete(packageName);
    _approvedSources.remove(packageName);
    await refreshAniyomiExtensions();
  }

  Future<void> _restoreApprovedSources(List<AniyomiExtensionInfo> installed) async {
    final box = await Hive.openBox(_approvedStore);
    final restored = <String, List<AniyomiExtensionSourceInfo>>{};
    for (final ext in installed) {
      final saved = box.get(ext.packageName);
      final key = _apkSignature(ext);
      if (saved is! Map || key == null || saved['signingKey'] != key ||
          saved['versionCode'] != ext.versionCode) continue;
      final records = saved['sources'];
      if (records is! List) continue;
      final infos = <AniyomiExtensionSourceInfo>[];
      for (final record in records) {
        if (record is! Map) continue;
        try {
          final info = AniyomiExtensionSourceInfo.fromMap(record);
          if (!infos.any((s) => s.id == info.id)) infos.add(info);
        } catch (_) {
          // Skip corrupted local metadata, without executing extension code.
        }
      }
      if (infos.isNotEmpty) restored[ext.packageName] = infos;
    }
    _approvedSources
      ..clear()
      ..addAll(restored);
  }

  List<ProviderDetails> get sources => _sources;

  void addSource(ProviderDetails source) {
    _sources.add(source);
  }

  void addSources(List<ProviderDetails> sources) {
    _sources.addAll(sources);
  }

  void removeSource(String identifier) {
    _sources.removeWhere((e) => e.identifier == identifier);
  }

  Future<void> loadProviders({bool clearBeforeLoading = true}) async {
    final providers = await ProviderManager().getSavedProviders();
    if (clearBeforeLoading) _sources.clear();
    _sources.addAll(providers);
    if (Platform.isAndroid) {
      await refreshAniyomiExtensions();
    }
  }

  Future<void> refreshAniyomiExtensions() async {
    if (!Platform.isAndroid) return;
    try {
      final installed = await AniyomiExtensionBridge.listInstalledExtensions();
      await _restoreApprovedSources(installed);
      _aniyomi.clear();
      _sources.removeWhere((e) =>
          AniyomiExtensionProvider.isExtensionId(e.identifier));
      for (final ext in installed) {
        // Only user-approved packages are enabled for execution here.
        // Discover source IDs when the user explicitly opts in, rather than
        // auto-executing all installed APK constructors during startup.
        final selected = _approvedSources[ext.packageName] ?? const <AniyomiExtensionSourceInfo>[];
        for (final source in selected) {
          final provider = AniyomiExtensionProvider(ext, selectedSource: source);
          final identifier = AniyomiExtensionProvider.identifier(ext.packageName, source.id);
          _aniyomi[identifier] = provider;
          _sources.add(ProviderDetails(
            name: '${source.name} [Ext] (${source.language})',
            identifier: identifier,
            version: ext.version,
            supportDownloads: false,
          ));
        }
      }
    } catch (_) {
      // Installed-extension discovery is optional: retain normal providers.
    }
  }

  Future<List<Map<String, String?>>> searchInSource(String source, String query) async {
    if (query.isEmpty) throw new Exception("ERR_EMPTY_QUERY");
    final searchResults = await (await _getProvider(source)).search(query);
    return searchResults;
  }

  Future<List<EpisodeDetails>> getAnimeEpisodes(String source, String link, {bool dub = false}) async {
    final info = await (await _getProvider(source)).getAnimeEpisodeLink(link, dub: dub);

    /// should be list of map corresponding to values of [EpisodeList]
    return info.map((e) => EpisodeDetails.fromMap(e)).toList();
  }

  Future<void> getDownloadSources(String source, String episodeUrl, Function(List<VideoStream>, bool) updateFunction,
      {bool dub = false, String? metadata}) async {
    await (await _getProvider(source)).getDownloadSources(episodeUrl, updateFunction, dub: dub, metadata: metadata);
  }

  Future<void> getStreams(String source, String episodeId, void Function(List<VideoStream>, bool) updateFunction,
      {bool dub = false, String? metadata}) async {
    await (await _getProvider(source)).getStreams(episodeId, updateFunction, dub: dub, metadata: metadata);
  }

  Future<AnimeProvider> _getProvider(String identifier) async {
    if (AniyomiExtensionProvider.isExtensionId(identifier)) {
      final provider = _aniyomi[identifier];
      if (provider == null) throw StateError('Aniyomi extension no longer installed');
      return provider;
    }
    final AnimeProvider? provider = identifier.endsWith('_inbuilt')
        ? getClass(identifier)
        : await _plugin.getProvider(identifier);
    if (provider == null) throw Exception("$identifier Provider doesnt exist!");
    return provider;
  }
}

final Map<String, AnimeProvider> sources = {
  "animepahe": AnimePahe(),
  "animeonsen": AnimeOnsen(),
  "gojo": Gojo(),
  "anizone": AniZone(),
  "animegg": Animegg(),
  "anikoto": Anikoto(),
};

AnimeProvider getClass(String source) {
  final match = sources[source.replaceAll("_inbuilt", "")]; // for ignoring _inbuilt suffix
  if (match == null) {
    throw Exception("Invalid Source!");
  }

  return match;
}

List<DropdownMenuEntry> getSourceDropdownList() {
  List<DropdownMenuEntry> widget = [];
  final sources = SourceManager.instance.sources;
  int count = 0;
  for (final source in sources) {
    widget.add(
      DropdownMenuEntry(
        value: source,
        label: "${source.name}${AniyomiExtensionProvider.isExtensionId(source.identifier) ? "" : source.version == "0.0.0.0" ? "" : " [Plugin]"}",
        trailingIcon:
            source.identifier == currentUserSettings?.preferredProvider ? Icon(Icons.star_border_rounded) : null,
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(appTheme.textMainColor),
          textStyle: WidgetStatePropertyAll(
            TextStyle(
              color: appTheme.textMainColor,
              fontFamily: "Rubik",
              fontSize: 18,
            ),
          ),
        ),
      ),
    );
    count = count++;
  }
  return widget;
}
