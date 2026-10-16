import 'package:animestream/ui/models/sources.dart';
import 'package:animestream/core/anime/providers/providerDetails.dart';
import 'package:animestream/core/anime/providers/aniyomiExtensionBridge.dart';
import 'package:animestream/core/anime/providers/extensionAniListMatcher.dart';
import 'package:animestream/core/anime/providers/providerManager.dart';
import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:flutter/material.dart';

/// Manage installed Android extension sources with explicit approval.
class PluginPage extends StatefulWidget {
  const PluginPage({super.key});

  @override
  State<PluginPage> createState() => _PluginPageState();
}

class _PluginPageState extends State<PluginPage> {
  final ProviderManager _manager = ProviderManager();
  List<ProviderDetails> _installed = [];
  List<AniyomiExtensionInfo> _apkExtensions = [];
  List<ProviderDetails> _available = [];
  bool _loading = true;
  String? _error;
  String? _busyId;
  String? _bulkProgress;
  String? _bulkSummary;
  List<String> _bulkFailures = [];
  final Map<String, String> _classDiagnostics = {};
  final Set<String> _testingExtensions = {};
  final Map<String, String> _searchDiagnostics = {};
  final Map<String, TextEditingController> _searchControllers = {};
  final Set<String> _searchingExtensions = {};
  final Map<String, List<Map<String, dynamic>>> _rankedResults = {};
  final Map<String, String> _episodeDiagnostics = {};
  final Set<String> _loadingEpisodes = {};
  final Map<String, List<Map<String, dynamic>>> _episodeSelections = {};
  final Map<String, String> _streamDiagnostics = {};
  final Set<String> _loadingStreams = {};

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() { _loading = true; _error = null; });
    try {
      final installed = await _manager.getSavedProviders();
      List<AniyomiExtensionInfo> apkExtensions = [];
      String? apkError;
      try {
        apkExtensions = await AniyomiExtensionBridge.listInstalledExtensions();
        await SourceManager.instance.refreshAniyomiExtensions();
      } catch (e) {
        apkError = 'Could not scan installed Android extensions: $e';
      }
      List<ProviderDetails> available = [];
      String? error;
      try {
        available = await _manager.fetchProvidersRepo();
      } catch (e) {
        error = 'Could not load the Provins catalog: $e';
      }
      if (!mounted) return;
      final ids = installed.map((e) => e.identifier).toSet();
      setState(() {
        _installed = installed;
        _apkExtensions = apkExtensions;
        _available = available.where((e) => !ids.contains(e.identifier)).toList();
        _error = [if (apkError != null) apkError, if (error != null) error].join('\n');
        if (_error!.isEmpty) _error = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not load saved providers: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Explicitly opt in to running every listed, not-already-approved APK.
  /// Per-package signer and version checks stay in SourceManager.
  Future<void> _enableAllInstalledSources() async {
    if (_loading || _busyId != null || _apkExtensions.isEmpty) return;
    final enabledIds = SourceManager.instance.sources
        .map((source) => source.identifier).toList();
    final pending = _apkExtensions.where((ext) =>
        !enabledIds.any((id) => id.startsWith(
            'aniyomi:${ext.packageName}#'))).toList();
    final skipped = _apkExtensions.length - pending.length;
    if (pending.isEmpty) {
      setState(() {
        _bulkSummary = 'All ${_apkExtensions.length} installed extensions '
            'are already enabled.';
        _bulkFailures = [];
        _bulkProgress = null;
      });
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Enable all installed extensions?'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('This will execute code from ${pending.length} installed '
                  'extension APKs to discover their sources. Only continue '
                  'if you trust EVERY extension below.'),
              const SizedBox(height: 10),
              const Text('An APK signature does not guarantee that its code '
                  'is safe. Some sources may contact external websites. '
                  'Already enabled sources will be skipped.'),
              const SizedBox(height: 10),
              SelectableText(pending.map((ext) =>
                  '${ext.name} (${ext.packageName})').join('\n')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialog, false),
              child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(dialog, true),
              child: const Text('Enable all')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _busyId = '__bulk_enable__';
      _bulkProgress = '0/${pending.length}';
      _bulkSummary = null;
      _bulkFailures = [];
    });

    var enabled = 0;
    final failures = <String>[];
    for (var i = 0; i < pending.length; i++) {
      final ext = pending[i];
      if (mounted) setState(() =>
          _bulkProgress = '${i + 1}/${pending.length}: ${ext.name}');
      try {
        await SourceManager.instance.enableExtensionSources(ext);
        enabled++;
      } catch (error) {
        // Do not display third-party exception messages: they might contain
        // media links, query tokens or authentication headers.
        final reason = error is StateError &&
                ['No sources found in this extension',
                 'Extension changed during approval; refresh and retry',
                 'Cannot approve an extension without a valid APK signing key']
                    .contains(error.message.toString())
            ? error.message.toString()
            : error.runtimeType.toString();
        failures.add('${ext.name}: $reason');
      }
    }

    if (!mounted) return;
    setState(() {
      _busyId = null;
      _bulkProgress = null;
      _bulkFailures = failures;
      _bulkSummary = 'Enabled $enabled; already enabled $skipped; '
          'failed ${failures.length}.';
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(_bulkSummary!),
      duration: const Duration(seconds: 6),
    ));
  }

  Future<void> _enableSources(AniyomiExtensionInfo ext) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Enable extension sources?'),
        content: Text('This executes code from ${ext.name} to discover its '
          'sources and makes the sources selectable in AnimeStream. '
          'Only proceed for an extension you trust.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialog, false),
            child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(dialog, true),
            child: const Text('Enable sources')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busyId = ext.packageName);
    try {
      await SourceManager.instance.enableExtensionSources(ext);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sources from ${ext.name} are now in the source list')));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(duration: const Duration(seconds: 12),
          content: Text('Source discovery failed: $error')));
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _showSourceSettings(
      AniyomiExtensionInfo ext, int sourceId, String sourceName) async {
    setState(() => _busyId = ext.packageName);
    try {
      final response = await AniyomiExtensionBridge.listSourcePreferences(
          ext.packageName, sourceId);
      if (!mounted) return;
      if (response['status'] != 'ok') {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Source settings: ${response['status']}')));
        return;
      }
      final items = ((response['preferences'] as List?) ?? const [])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item)).toList();
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, refresh) => SafeArea(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(16),
              children: [
                Text('$sourceName settings',
                    style: Theme.of(ctx).textTheme.titleLarge),
                if (items.isEmpty)
                  const ListTile(title: Text('No supported source settings')),
                for (final item in items)
                  if (item['type'] == 'list')
                    ListTile(
                      title: Text(item['title']?.toString() ?? ''),
                      subtitle: Text(item['value']?.toString() ?? ''),
                      onTap: () async {
                        final values = (item['values'] as List?) ?? const [];
                        final entries = (item['entries'] as List?) ?? const [];
                        if (values.length != entries.length) return;
                        final selected = await showDialog<String>(
                          context: ctx,
                          builder: (dialog) => SimpleDialog(
                            title: Text(item['title']?.toString() ?? 'Select'),
                            children: [
                              for (var i = 0; i < values.length; i++)
                                SimpleDialogOption(
                                  onPressed: () => Navigator.pop(
                                      dialog, values[i].toString()),
                                  child: Text(entries[i].toString()),
                                ),
                            ],
                          ),
                        );
                        if (selected == null) return;
                        final result = await AniyomiExtensionBridge.updateSourcePreference(
                            ext.packageName, sourceId, item['key'].toString(), selected);
                        if (!ctx.mounted) return;
                        if (result['status'] == 'updated') {
                          refresh(() => item['value'] = selected);
                        } else {
                          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                              content: Text('Save failed: ${result['status']}')));
                        }
                      },
                    )
                  else if (item['type'] == 'boolean')
                    SwitchListTile(
                      title: Text(item['title']?.toString() ?? ''),
                      value: item['value'] == true,
                      onChanged: (value) async {
                        final result = await AniyomiExtensionBridge.updateSourcePreference(
                            ext.packageName, sourceId, item['key'].toString(), value);
                        if (!ctx.mounted) return;
                        if (result['status'] == 'updated') {
                          refresh(() => item['value'] = value);
                        } else {
                          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                              content: Text('Save failed: ${result['status']}')));
                        }
                      },
                    ),
              ],
            ),
          ),
        ),
      );
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Source settings failed: ${error.runtimeType}')));
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _disableExtensionSources(AniyomiExtensionInfo ext) async {
    setState(() => _busyId = ext.packageName);
    try {
      await SourceManager.instance.disableExtensionSources(ext.packageName);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sources disabled for ${ext.name}')));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not disable sources: ${error.runtimeType}')));
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _inspectClass(AniyomiExtensionInfo ext) async {
    setState(() => _classDiagnostics[ext.packageName] = 'Checking class...');
    try {
      final data = await AniyomiExtensionBridge.inspectExtensionClass(ext.packageName);
      if (!mounted) return;
      final fields = <String, String>{
        'status': '${data['status'] ?? ''}',
        'dexInspectionStatus': '${data['dexInspectionStatus'] ?? '(not reported)'}',
        'hostApiDependencyStatus': '${data['hostApiDependencyStatus'] ?? ''}',
        'missingAniyomiHostApiTypes': '${data['missingAniyomiHostApiTypes'] ?? ''}',
        'dexSuperclass': '${data['dexSuperclass'] ?? ''}',
        'dexHierarchy': '${data['dexHierarchy'] ?? '(not reported)'}',
        'dexTransitiveMissingDependencies': '${data['dexTransitiveMissingDependencies'] ?? '(not reported)'}',
        'dexHierarchyScanErrors': '${data['dexHierarchyScanErrors'] ?? '(not reported)'}',
        'dexObfuscatedSuperclassResolved': '${data['dexObfuscatedSuperclassResolved'] ?? '(not reported)'}',
        'hostApiClassProbe': '${data['hostApiClassProbe'] ?? '(not reported)'}',
        'missingHostApiClassCount': '${data['missingHostApiClassCount'] ?? '(not reported)'}',
        'dexInterfaces': '${data['dexInterfaces'] ?? ''}',
        'dexClassLocation': '${data['dexClassLocation'] ?? ''}',
        'dexMissingDirectDependencies': '${data['dexMissingDirectDependencies'] ?? ''}',
        'dexDependencyScanErrors': '${data['dexDependencyScanErrors'] ?? ''}',
        'dexClassLoaderResult': '${data['dexClassLoaderResult'] ?? ''}',
        'pathClassLoaderResult': '${data['pathClassLoaderResult'] ?? ''}',
        'resolvedByLoader': '${data['resolvedByLoader'] ?? ''}',
        'className': '${data['className'] ?? ''}',
        'declaredClass': '${data['declaredClass'] ?? ''}',
        'declaredFactory': '${data['declaredFactory'] ?? ''}',
        'declaredEntryPoints': '${data['declaredEntryPoints'] ?? ''}',
        'entryPointsInDex': '${data['entryPointsInDex'] ?? ''}',
        'declaredClassInDex': '${data['declaredClassInDex'] ?? ''}',
        'targetClassInDex': '${data['targetClassInDex'] ?? ''}',
        'dexClassCount': '${data['dexClassCount'] ?? ''}',
        'candidates': '${data['candidates'] ?? ''}',
        'extensionPackageClasses': '${data['extensionPackageClasses'] ?? ''}',
        'hostApiPresent': '${data['hostApiPresent'] ?? ''}',
        'apkFiles': '${data['apkFiles'] ?? ''}',
        'dexInventory': '${data['dexInventory'] ?? ''}',
        'dexScanErrors': '${data['dexScanErrors'] ?? ''}',
        'error': '${data['error'] ?? ''}',
        'missingDependency': '${data['missingDependency'] ?? ''}',
        'dependencyClassInDex': '${data['dependencyClassInDex'] ?? ''}',
        'entryPointResolutionFailed': '${data['entryPointResolutionFailed'] ?? ''}',
        'exceptionTypes': '${data['exceptionTypes'] ?? ''}',
        'rootCause': '${data['rootCause'] ?? ''}',
        'diagnosis': '${data['diagnosis'] ?? ''}',
      };
      setState(() => _classDiagnostics[ext.packageName] = fields.entries
          .where((entry) => entry.value.isNotEmpty)
          .map((entry) => '${entry.key}: ${entry.value}')
          .join('\n'));
    } catch (e) {
      if (mounted) setState(() => _classDiagnostics[ext.packageName] = 'Inspection error: $e');
    }
  }

  Future<void> _confirmInstantiation(AniyomiExtensionInfo ext) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Run extension constructor?'),
        content: Text('This runs code from ${ext.name} on your device. '
            'Only continue if you trust this installed extension.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true),
              child: const Text('Run test')),
        ],
      ),
    );
    if (confirmed == true && mounted) await _testInstantiation(ext);
  }

  Future<void> _testInstantiation(AniyomiExtensionInfo ext) async {
    setState(() => _testingExtensions.add(ext.packageName));
    try {
      final data = await AniyomiExtensionBridge.testExtensionInstantiation(ext.packageName);
      if (!mounted) return;
      final result = 'Instantiation: ${data['extensionInstantiationStatus'] ?? 'unknown'}'
          '\nInstance class: ${data['extensionInstanceClass'] ?? '(none)'}'
          '\nError: ${data['extensionInstantiationError'] ?? '(none)'}';
      setState(() {
        _classDiagnostics[ext.packageName] =
            '${_classDiagnostics[ext.packageName] ?? ''}\n$result'.trim();
      });
    } catch (error) {
      if (mounted) {
        setState(() => _classDiagnostics[ext.packageName] =
            '${_classDiagnostics[ext.packageName] ?? ''}\nInstantiation test failed: $error'.trim());
      }
    } finally {
      if (mounted) setState(() => _testingExtensions.remove(ext.packageName));
    }
  }

  Future<void> _confirmSearch(AniyomiExtensionInfo ext) async {
    final controller = _searchControllers.putIfAbsent(
        ext.packageName, () => TextEditingController());
    final query = controller.text.trim();
    if (query.isEmpty) {
      setState(() => _searchDiagnostics[ext.packageName] = 'Enter a search query.');
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Run extension search?'),
        content: Text('This executes code from ${ext.name} and may connect to '
            'external websites. Continue only if you trust this extension.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true),
              child: const Text('Search')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _searchingExtensions.add(ext.packageName);
      _searchDiagnostics[ext.packageName] = 'Searching...';
      _rankedResults.remove(ext.packageName);
      _episodeDiagnostics.remove(ext.packageName);
      _episodeSelections.remove(ext.packageName);
      _streamDiagnostics.remove(ext.packageName);
    });
    try {
      final data = await AniyomiExtensionBridge.testExtensionSearch(
          ext.packageName, query);
      if (!mounted) return;
      final results = (data['results'] as List?) ?? const [];
      final networkDiagnostics =
          (data['networkDiagnostics'] as List?) ?? const [];
      final networkLines = networkDiagnostics.map((entry) {
        if (entry is! Map) return 'Unknown request';
        final method = entry['method'] ?? '';
        final host = entry['host'] ?? '';
        final path = entry['path'] ?? '';
        final status = entry['status'] ?? '';
        final authorization = entry['authorization'] ?? 'unknown';
        final keyword = entry.containsKey('keywordMatchesQuery')
            ? ', keyword matched: ${entry['keywordMatchesQuery']}'
            : '';
        final mitigation = entry.containsKey('cfMitigated')
            ? ', cf-mitigated: ${entry['cfMitigated']}'
            : '';
        return '$method $host$path → HTTP $status, auth: $authorization$keyword$mitigation';
      }).join('\n');
      final summary = <String>[
        'Status: ${data['status'] ?? 'unknown'}',
        if (data['fallbackUsed'] == true)
          'Search fallback: built-in AnimeOnsen API (extension returned 403)',
        if (data['fallbackStatus'] != null)
          'Fallback: ${data['fallbackStatus']} (${data['fallbackErrorType'] ?? 'unknown'})',
        if (data['error'] != null) 'Error: ${data['error']}',
        if (data['warning'] != null) 'Warning: ${data['warning']}',
        if (data['titleMatchCount'] != null)
          'Matching displayed titles: ${data['titleMatchCount']} of ${results.length}',
        'Results: ${data['resultCount'] ?? results.length}',
        if (data['resultRelevance'] != null)
          'Relevance: ${data['resultRelevance']}',
        if (data['alternateEndpoint'] is Map)
          '123Anime /search endpoint test: ${data['alternateEndpoint']}',
        if (networkDiagnostics.isNotEmpty)
          'Network diagnostics (no secrets):\n$networkLines',
        if (results.isNotEmpty)
          'Select a result below to test episode loading. AniList matches are suggestions, not automatic source links.',
      ].join('\n\n');
      setState(() => _searchDiagnostics[ext.packageName] = summary);
      if (results.isNotEmpty) {
        try {
          final ranked = await ExtensionAniListMatcher.rank(query, results);
          if (!mounted) return;
          setState(() => _rankedResults[ext.packageName] = ranked);
        } catch (e) {
          if (!mounted) return;
          setState(() {
            _rankedResults[ext.packageName] = results.whereType<Map>()
                .map((item) => <String, dynamic>{
                  'title': (item['title'] ?? '').toString(),
                  'url': (item['url'] ?? '').toString(),
                  'sourceCover': (item['cover'] ?? '').toString(),
                  'matchStatus': 'manual_selection_required',
                  'score': 0,
                }).toList();
            _searchDiagnostics[ext.packageName] =
                '$summary\n\nAniList matching unavailable: $e. '
                'Source results remain available for manual selection.';
          });
        }
      }
    } catch (error) {
      if (mounted) setState(() =>
          _searchDiagnostics[ext.packageName] = 'Search failed: $error');
    } finally {
      if (mounted) setState(() => _searchingExtensions.remove(ext.packageName));
    }
  }

  Future<void> _testEpisodes(
      AniyomiExtensionInfo ext, Map<String, dynamic> selected) async {
    final url = (selected['url'] ?? '').toString();
    final title = (selected['title'] ?? '').toString();
    if (url.isEmpty || title.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Test episode list?'),
        content: Text('Load episodes from ${ext.name} for:\n$title'
            '\n\nThis executes the installed extension and makes network calls.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Test episodes'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _loadingEpisodes.add(ext.packageName);
      _episodeDiagnostics[ext.packageName] = 'Loading episodes for $title...';
      _episodeSelections.remove(ext.packageName);
      _streamDiagnostics.remove(ext.packageName);
    });
    try {
      final response = await AniyomiExtensionBridge.testExtensionEpisodes(
          ext.packageName, url, title);
      final items = response['episodes'] as List? ?? const [];
      final text = <String>[
        'Source: $title',
        'Status: ${response['status'] ?? 'unknown'}',
        if (response['error'] != null) 'Error: ${response['error']}',
        'Episodes: ${response['episodeCount'] ?? items.length}',
        if (response['truncated'] == true) 'Showing first 100 episodes',
        for (final entry in items)
          if (entry is Map)
            '${entry['name'] ?? 'Untitled'} '
            '(episode ${entry['number'] ?? '?'}) — ${entry['url'] ?? ''}',
      ].join('\n');
      if (mounted) setState(() {
        _episodeDiagnostics[ext.packageName] = text;
        _episodeSelections[ext.packageName] = items.whereType<Map>()
            .map((e) => <String, dynamic>{
              'name': (e['name'] ?? '').toString(),
              'url': (e['url'] ?? '').toString(),
              'number': e['number'],
            }).where((e) => (e['url'] as String).isNotEmpty).toList();
      });
    } catch (e) {
      if (mounted) setState(() =>
          _episodeDiagnostics[ext.packageName] = 'Episode test failed: $e');
    } finally {
      if (mounted) setState(() => _loadingEpisodes.remove(ext.packageName));
    }
  }

  Future<void> _testStreams(
      AniyomiExtensionInfo ext, Map<String, dynamic> episode) async {
    final name = (episode['name'] ?? '').toString();
    final url = (episode['url'] ?? '').toString();
    if (name.isEmpty || url.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Test streams?'),
        content: Text('Resolve video streams for $name using ${ext.name}?'
            '\n\nThis executes installed extension code and makes network '
            'requests. No playback will start. Stream URLs and credentials '
            'will not be displayed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Test streams')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _loadingStreams.add(ext.packageName);
      _streamDiagnostics[ext.packageName] = 'Resolving streams for $name...';
    });
    try {
      final data = await AniyomiExtensionBridge.testExtensionStreams(
          ext.packageName, url, name);
      if (!mounted) return;
      final videos = (data['videos'] as List?) ?? const [];
      final lines = <String>[
        'Episode: $name',
        'Status: ${data['status'] ?? 'unknown'}',
        if (data['error'] != null) 'Error: ${data['error']}',
        if (data['failureStage'] != null)
          'Failure stage: ${data['failureStage']}',
        if (data['missingClasses'] is List &&
            (data['missingClasses'] as List).isNotEmpty)
          'Missing host/API classes: ${(data['missingClasses'] as List).join(', ')}',
        if (data['errorTypes'] is List)
          'Exception chain: ${(data['errorTypes'] as List).join(' -> ')}',
        if (data['hostFrames'] is List &&
            (data['hostFrames'] as List).isNotEmpty)
          'Relevant methods: ${(data['hostFrames'] as List).join(', ')}',
        'Videos found: ${data['videoCount'] ?? videos.length}',
        if (data['diagnosis'] != null)
          'Diagnosis: ${data['diagnosis']}',
        if (data['status'] == 'stream_list_empty')
          'No video streams were returned. The test is NOT considered successful.',
        if (data['safeRequestSummary'] is List)
          'Request stages (no URLs or secrets):',
        if (data['safeRequestSummary'] is List)
          for (final stage in data['safeRequestSummary'] as List)
            if (stage is Map)
              '${stage['stage'] ?? 'unknown'}: '
              '${stage['host'] ?? ''} • HTTP ${stage['status'] ?? '?'}'
              ' • ${stage['contentType'] ?? ''}'
              ' • cached: ${stage['fromCache'] ?? '?'}'
              ' • tabs: ${stage['serverTabCount'] ?? '-'}'
              ' • target: ${stage['targetShape'] ?? '-'}'
              ' • grabber present: ${stage['grabberPresent'] ?? '-'}'
              ' • parsed JSON: ${stage['jsonObject'] ?? '-'}',
        if (data['truncated'] == true) 'Showing first 40 streams',
        for (final video in videos)
          if (video is Map)
            '${video['quality'] ?? 'Unknown'} • ${video['format'] ?? 'unknown'}'
            ' • ${video['host'] ?? 'unknown host'}'
            ' • subtitles ${video['subtitleCount'] ?? 0}'
            ' • audio ${video['audioCount'] ?? 0}',
        'URLs, tokens, cookies and request headers are not displayed.',
      ];
      setState(() => _streamDiagnostics[ext.packageName] = lines.join('\n'));
    } catch (e) {
      if (mounted) setState(() =>
          _streamDiagnostics[ext.packageName] = 'Stream test failed: $e');
    } finally {
      if (mounted) setState(() => _loadingStreams.remove(ext.packageName));
    }
  }

  Widget _extensionResultTile(
      AniyomiExtensionInfo ext, Map<String, dynamic> item) {
    final score = item['score'] is int ? item['score'] as int : 0;
    final url = (item['anilistCover'] ?? item['sourceCover'] ?? '').toString();
    final matched = item['anilistId'] != null;
    final title = (item['title'] ?? '').toString();
    final isDub = RegExp(r'\b(?:dub|dubbed)\b', caseSensitive: false)
        .hasMatch(title);
    final season = RegExp(r'\b\d+(?:st|nd|rd|th)?\s+season\b',
        caseSensitive: false).firstMatch(title)?.group(0);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 6),
      leading: url.startsWith('http')
          ? Image.network(url, width: 54, height: 78,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.movie))
          : const Icon(Icons.movie),
      title: Text(title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Source: ${ext.name} (external)'
              '${season == null ? '' : ' • $season'}'
              ' • ${isDub ? 'Dub' : 'Sub/unknown'}'),
          if (matched)
            Text('AniList: ${item['anilistTitle']} '
                 '(ID ${item['anilistId']}, score $score)'),
          if (!matched)
            const Text('AniList match unconfirmed — select manually'),
          Text('URL: ${item['url']}', maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ],
      ),
      trailing: TextButton(
        onPressed: _loadingEpisodes.contains(ext.packageName)
            ? null : () => _testEpisodes(ext, item),
        child: const Text('Test episodes'),
      ),
    );
  }

  @override
  void dispose() {
    for (final controller in _searchControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _install(ProviderDetails item) async {
    setState(() => _busyId = item.identifier);
    try {
      final code = await _manager.fetchProviderCode(item.identifier);
      if (code == null) throw Exception('No source code returned');
      await _manager.saveProvider(item.copyWith(code: code));
      await _refresh();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Install failed: $e')));
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _remove(ProviderDetails item) async {
    setState(() => _busyId = item.identifier);
    try {
      await _manager.removeProvider(item);
      await _refresh();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Remove failed: $e')));
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Widget _items(List<ProviderDetails> items, {required bool installed}) {
    if (items.isEmpty) return const Center(child: Text('No providers found'));
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return ListTile(
          title: Text(item.name),
          subtitle: Text('v${item.version} • ${item.identifier}'),
          trailing: _busyId == item.identifier
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator())
              : TextButton(
                  onPressed: _busyId != null ? null :
                      () => installed ? _remove(item) : _install(item),
                  child: Text(installed ? 'Remove' : 'Save code'),
                ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: appTheme.backgroundColor,
        appBar: AppBar(
          title: const Text('Manage Providers [Beta]'),
          actions: [
            IconButton(onPressed: _loading || _busyId != null ? null : _refresh,
              icon: const Icon(Icons.refresh), tooltip: 'Refresh catalog'),
          ],
          bottom: const TabBar(tabs: [
            Tab(text: 'Installed'),
            Tab(text: 'Available'),
          ]),
        ),
        body: Column(children: [
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text('Installed Android extensions can run as [Ext] sources '
              'after explicit approval. Other downloaded provider code '
              'remains stored only. Enable APKs you trust.'),
          ),
          if (_error != null)
            Padding(padding: const EdgeInsets.all(12),
              child: SelectableText(_error!, style: const TextStyle(color: Colors.orange))),
          Expanded(child: _loading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(children: [
                  ListView(children: [
                    const Padding(padding: EdgeInsets.all(8), child: Text('Installed Android APK extensions')),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FilledButton.icon(
                          onPressed: _busyId != null || _apkExtensions.isEmpty
                              ? null : _enableAllInstalledSources,
                          icon: const Icon(Icons.playlist_add_check),
                          label: const Text('Enable all installed sources'),
                        ),
                      ),
                    ),
                    if (_bulkProgress != null)
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text('Enabling: $_bulkProgress'),
                      ),
                    if (_bulkSummary != null)
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(_bulkSummary!),
                      ),
                    if (_bulkFailures.isNotEmpty)
                      ExpansionTile(
                        title: Text('Failed extensions (${_bulkFailures.length})'),
                        children: [
                          for (final message in _bulkFailures)
                            ListTile(dense: true, title: Text(message)),
                        ],
                      ),
                    if (_apkExtensions.isEmpty)
                      const Padding(padding: EdgeInsets.all(8), child: Text('No installed Aniyomi APK extensions detected')),
                    for (final ext in _apkExtensions)
                      ExpansionTile(
                        title: Text(ext.name),
                        subtitle: Text('${ext.packageName} • v${ext.version}'),
                        childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: SelectableText(
                              'Extension detected — select this [Ext] source on a series page to watch (experimental)'
                              '\nSource class: ${ext.sourceClass ?? "unknown"}'
                              '${ext.sourceFactory != null ? "\nSource factory: ${ext.sourceFactory}" : ""}',
                            ),
                          ),
                          if (_classDiagnostics[ext.packageName] != null)
                            ExpansionTile(
                              title: const Text('Class diagnostics'),
                              children: [
                                SelectableText(_classDiagnostics[ext.packageName]!),
                              ],
                            ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _searchControllers.putIfAbsent(
                                ext.packageName, () => TextEditingController()),
                            decoration: const InputDecoration(
                              labelText: 'Extension search test',
                              hintText: 'Anime title',
                              border: OutlineInputBorder(),
                            ),
                            textInputAction: TextInputAction.search,
                            onSubmitted: (_) => _searchingExtensions.contains(ext.packageName)
                                ? null : _confirmSearch(ext),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _searchingExtensions.contains(ext.packageName)
                                  ? null : () => _confirmSearch(ext),
                              child: Text(_searchingExtensions.contains(ext.packageName)
                                  ? 'Searching...' : 'Test search'),
                            ),
                          ),
                          if (_searchDiagnostics[ext.packageName] != null)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: SelectableText(_searchDiagnostics[ext.packageName]!),
                            ),
                          if (_rankedResults[ext.packageName] != null) ...[
                            const Divider(),
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text('Extension results — AniList ranking',
                                  style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            for (final result in _rankedResults[ext.packageName]!)
                              _extensionResultTile(ext, result),
                          ],
                          if (_episodeDiagnostics[ext.packageName] != null)
                            ExpansionTile(
                              initiallyExpanded: true,
                              title: const Text('Episode test results'),
                              children: [
                                SelectableText(
                                    _episodeDiagnostics[ext.packageName]!),
                              ],
                            ),
                          if (_episodeSelections[ext.packageName]?.isNotEmpty == true)
                            ExpansionTile(
                              initiallyExpanded: true,
                              title: const Text('Select episode for stream test'),
                              children: [
                                for (final episode in _episodeSelections[ext.packageName]!)
                                  ListTile(
                                    dense: true,
                                    title: Text(episode['name']?.toString() ?? 'Episode'),
                                    subtitle: Text('Episode ${episode['number'] ?? '?'}'),
                                    trailing: TextButton(
                                      onPressed: _loadingStreams.contains(ext.packageName)
                                          ? null : () => _testStreams(ext, episode),
                                      child: const Text('Test streams'),
                                    ),
                                  ),
                              ],
                            ),
                          if (_streamDiagnostics[ext.packageName] != null)
                            ExpansionTile(
                              initiallyExpanded: true,
                              title: const Text('Stream test results'),
                              children: [
                                SelectableText(_streamDiagnostics[ext.packageName]!),
                              ],
                            ),
                          for (final provider in SourceManager.instance.sources.where(
                              (item) => item.identifier.startsWith(
                                  'aniyomi:${ext.packageName}#')))
                            if (int.tryParse(provider.identifier.split('#').last) != null)
                              ListTile(
                                dense: true,
                                title: Text(provider.name),
                                trailing: TextButton.icon(
                                  onPressed: _busyId != null ? null :
                                      () => _showSourceSettings(ext,
                                        int.parse(provider.identifier.split('#').last),
                                        provider.name),
                                  icon: const Icon(Icons.tune),
                                  label: const Text('Source settings'),
                                ),
                              ),
                          Wrap(
                            alignment: WrapAlignment.end,
                            spacing: 8,
                            children: [
                              TextButton.icon(
                                onPressed: _busyId != null ? null : () => _enableSources(ext),
                                icon: const Icon(Icons.playlist_add_check),
                                label: const Text('Enable / refresh sources'),
                              ),
                              TextButton.icon(
                                onPressed: _busyId != null ? null :
                                    () => _disableExtensionSources(ext),
                                icon: const Icon(Icons.block_outlined),
                                label: const Text('Disable sources'),
                              ),
                            ],
                          ),
                          Wrap(
                            alignment: WrapAlignment.end,
                            spacing: 8,
                            children: [
                              TextButton(
                                onPressed: _testingExtensions.contains(ext.packageName)
                                    ? null : () => _inspectClass(ext),
                                child: const Text('Test class'),
                              ),
                              TextButton(
                                onPressed: _testingExtensions.contains(ext.packageName)
                                    ? null : () => _confirmInstantiation(ext),
                                child: Text(_testingExtensions.contains(ext.packageName)
                                    ? 'Testing...' : 'Test instantiation'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    const Divider(),
                    if (_installed.isEmpty)
                      const ListTile(title: Text('No additional Dart providers installed')),
                    for (final item in _installed)
                      ListTile(
                        title: Text(item.name),
                        subtitle: Text('v${item.version} • ${item.identifier}'),
                        trailing: _busyId == item.identifier
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator())
                            : TextButton(
                                onPressed: _busyId != null ? null : () => _remove(item),
                                child: const Text('Remove'),
                              ),
                      ),
                  ]),
                  _items(_available, installed: false),
                ])),
        ]),
      ),
    );
  }
}
