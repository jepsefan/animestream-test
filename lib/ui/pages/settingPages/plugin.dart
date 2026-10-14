import 'package:animestream/core/anime/providers/providerDetails.dart';
import 'package:animestream/core/anime/providers/aniyomiExtensionBridge.dart';
import 'package:animestream/core/anime/providers/extensionAniListMatcher.dart';
import 'package:animestream/core/anime/providers/providerManager.dart';
import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:flutter/material.dart';

/// Experimental catalog and local source storage. Execution is not supported yet.
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
  final Map<String, String> _classDiagnostics = {};
  final Set<String> _testingExtensions = {};
  final Map<String, String> _searchDiagnostics = {};
  final Map<String, TextEditingController> _searchControllers = {};
  final Set<String> _searchingExtensions = {};
  final Map<String, List<Map<String, dynamic>>> _rankedResults = {};
  final Map<String, String> _episodeDiagnostics = {};
  final Set<String> _loadingEpisodes = {};

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
      if (mounted) setState(() => _episodeDiagnostics[ext.packageName] = text);
    } catch (e) {
      if (mounted) setState(() =>
          _episodeDiagnostics[ext.packageName] = 'Episode test failed: $e');
    } finally {
      if (mounted) setState(() => _loadingEpisodes.remove(ext.packageName));
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
              errorBuilder: (_, _, _) => const Icon(Icons.movie))
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
            IconButton(onPressed: _loading ? null : _refresh,
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
            child: Text('Experimental: providers can be downloaded and stored, '
              'but cannot run or appear as playable sources yet. '
              'Only install code from sources you trust.'),
          ),
          if (_error != null)
            Padding(padding: const EdgeInsets.all(12),
              child: SelectableText(_error!, style: const TextStyle(color: Colors.orange))),
          Expanded(child: _loading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(children: [
                  ListView(children: [
                    const Padding(padding: EdgeInsets.all(8), child: Text('Detected Android APK extensions (not loaded)')),
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
                              'Extension detected — playback not yet supported'
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
                      const ListTile(title: Text('No saved providers found')),
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
