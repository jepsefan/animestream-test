import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/data/settings.dart';
import 'package:animestream/core/data/types.dart';
import 'package:animestream/ui/models/sources.dart';
import 'package:animestream/ui/pages/settingPages/common.dart';
import 'package:flutter/material.dart';

/// Built-in source and metadata switches. Extension APK approvals are separate.
class BuiltInProvidersPage extends StatefulWidget {
  const BuiltInProvidersPage({super.key});

  @override
  State<BuiltInProvidersPage> createState() => _BuiltInProvidersPageState();
}

class _BuiltInProvidersPageState extends State<BuiltInProvidersPage> {
  bool _loaded = false;
  bool _saving = false;
  final Set<String> _disabledSources = {};
  final Set<String> _disabledMetadata = {};
  final Set<String> _fallbacks = {'mal', 'kitsu'};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final settings = await Settings().getSettings();
    if (!mounted) return;
    setState(() {
      _disabledSources
        ..clear()
        ..addAll(settings.disabledProviders ?? const <String>[]);
      _disabledMetadata
        ..clear()
        ..addAll(settings.disabledMetadataProviders ?? const <String>[]);
      _fallbacks
        ..clear()
        ..addAll(settings.metadataFallbacks ?? const <String>['mal', 'kitsu']);
      _loaded = true;
    });
  }

  Future<void> _change(String id, bool enabled, String category) async {
    if (_saving || (category == 'fallback' && enabled &&
        _disabledMetadata.contains(id))) return;
    setState(() {
      _saving = true;
      final target = category == 'source' ? _disabledSources
          : category == 'metadata' ? _disabledMetadata : _fallbacks;
      if (category == 'fallback') {
        if (enabled) { target.add(id); } else { target.remove(id); }
      } else {
        if (enabled) { target.remove(id); } else { target.add(id); }
        if (category == 'metadata' && !enabled) _fallbacks.remove(id);
      }
    });
    try {
      await Settings().writeSettings(SettingsModal(
        disabledProviders: _disabledSources.toList(),
        disabledMetadataProviders: _disabledMetadata.toList(),
        metadataFallbacks: ['mal', 'kitsu'].where(_fallbacks.contains).toList(),
      ));
      SourceManager.instance.applyDisabledInbuiltProviders(_disabledSources);
      final preferred = currentUserSettings?.preferredProvider;
      final available = SourceManager.instance.sources;
      if (preferred != null && _disabledSources.contains(preferred) &&
          available.isNotEmpty) {
        await Settings().writeSettings(
            SettingsModal(preferredProvider: available.first.identifier));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save provider settings: $error')),
        );
        await _load();
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _switch(String label, String subtitle, bool value,
      void Function(bool) change) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
      activeThumbColor: appTheme.accentColor,
      title: Text(label, style: textStyle().copyWith(fontSize: 18)),
      subtitle: Text(subtitle),
      value: value,
      onChanged: _saving ? null : change,
    );
  }

  Widget _heading(String label) => Padding(
    padding: const EdgeInsets.only(left: 10, top: 28, bottom: 10),
    child: Text(label, style: textStyle().copyWith(
      fontSize: 23, fontWeight: FontWeight.bold)),
  );

  Widget _note(String label) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    child: Text(label, style: TextStyle(
        color: appTheme.textMainColor.withValues(alpha: 0.7))),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appTheme.backgroundColor,
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: pagePadding(context, bottom: true),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    settingPagesTitleHeader(context, 'Built-in providers'),
                    _note('Hide built-in sources without uninstalling extensions. '
                        'Your choices are stored locally.'),
                    _heading('Streaming'),
                    for (final provider in SourceManager.instance.inbuiltSources)
                      _switch(provider.name, provider.identifier,
                        !_disabledSources.contains(provider.identifier),
                        (enabled) => _change(provider.identifier, enabled, 'source')),
                    if (SourceManager.instance.inbuiltSources.every(
                        (p) => _disabledSources.contains(p.identifier)))
                      _note('All built-in video sources are disabled. '
                          'Enable a source or use an installed extension.'),
                    _heading('Metadata'),
                    _note('Metadata switches control discovery, not account logins. '
                        'Existing AniList-based library entries may still need AniList.'),
                    _switch('AniList', 'Primary anime metadata',
                      !_disabledMetadata.contains('anilist'),
                      (enabled) => _change('anilist', enabled, 'metadata')),
                    _switch('MyAnimeList', 'Metadata fallback service',
                      !_disabledMetadata.contains('mal'),
                      (enabled) => _change('mal', enabled, 'metadata')),
                    _switch('Simkl', 'SIMKL account and anime metadata',
                      !_disabledMetadata.contains('simkl'),
                      (enabled) => _change('simkl', enabled, 'metadata')),
                    _heading('Metadata fallbacks'),
                    _note('When AniList is unavailable: MyAnimeList, then Kitsu. '
                        'Only enabled fallbacks will be tried.'),
                    _switch('MyAnimeList',
                      _disabledMetadata.contains('mal')
                          ? 'Enable MyAnimeList under Metadata first' : 'First fallback',
                      _fallbacks.contains('mal') && !_disabledMetadata.contains('mal'),
                      (enabled) => _change('mal', enabled, 'fallback')),
                    _switch('Kitsu', 'Second fallback for anime',
                      _fallbacks.contains('kitsu'),
                      (enabled) => _change('kitsu', enabled, 'fallback')),
                    if (_fallbacks.isEmpty)
                      _note('All fallbacks are off. If AniList fails, '
                          'search and discovery may show errors.'),
                  ],
                ),
              ),
            ),
    );
  }
}
