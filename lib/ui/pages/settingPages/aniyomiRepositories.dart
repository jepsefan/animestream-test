import 'package:animestream/core/anime/providers/aniyomiRepositoryManager.dart';
import 'package:flutter/material.dart';
import 'package:animestream/core/anime/providers/aniyomiExtensionBridge.dart';

/// Browse user-added Aniyomi extension repositories without executing APKs.
class AniyomiRepositoriesPage extends StatefulWidget {
  const AniyomiRepositoriesPage({super.key});

  @override
  State<AniyomiRepositoriesPage> createState() =>
      _AniyomiRepositoriesPageState();
}

class _AniyomiRepositoriesPageState extends State<AniyomiRepositoriesPage> with WidgetsBindingObserver {
  final _manager = AniyomiRepositoryManager();
  final _url = TextEditingController();
  List<Uri> _repos = [];
  final Map<String, List<AniyomiCatalogEntry>> _catalogs = {};
  final Map<String, String> _errors = {};
  bool _busy = false;
  bool _loadingCatalogs = true;
  String _search = '';
  String _language = 'all';
  int _section = 2;
  Map<String, AniyomiExtensionInfo> _installed = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _reload();
    _refreshInstalled();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Android installation is completed/cancelled outside Flutter. Ask the
      // package manager again; never treat opening the installer as success.
      _refreshInstalled();
    }
  }

  Future<void> _refreshInstalled() async {
    try {
      final list = await AniyomiExtensionBridge.listInstalledExtensions();
      if (mounted) setState(() => _installed = {
        for (final ext in list) ext.packageName: ext,
      });
    } catch (_) { /* Android-only catalog display */ }
  }

  Future<void> _install(AniyomiCatalogEntry entry, Uri repo) async {
    if (_busy) return;
    await _refreshInstalled();
    final fingerprint = await _manager.trustedFingerprint(repo);
    if (fingerprint == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trust the repository signing key first')));
      return;
    }
    final installed = _installed[entry.packageName];
    final isUpdate = installed != null;
    if (!mounted) return;
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(isUpdate ? 'Update extension?' : 'Install extension?'),
        content: SelectableText('${entry.name}\n'
          'Publisher certificate SHA-256:\n$fingerprint\n\n'
          'The APK will be downloaded, cryptographically verified, '
          'then handed to Android for installation. Third-party APKs '
          'can execute code and access the network.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialog, false),
              child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialog, true),
              child: Text(isUpdate ? 'Verify & update' : 'Verify & install')),
        ],
      ),
    );
    if (approved != true || !mounted) return;
    setState(() => _busy = true);
    try {
      // Re-fetch the current repository key/index before installing.
      final catalog = await _manager.fetchExtensions(repo);
      final fresh = catalog.where((e) => e.packageName == entry.packageName &&
        e.versionCode == entry.versionCode && e.apkUrl == entry.apkUrl).firstOrNull;
      if (fresh == null) throw StateError('Catalog entry changed. Refresh to continue.');
      final response = await AniyomiExtensionBridge.installVerifiedExtension(
        indexUrl: repo,
        apkUrl: fresh.apkUrl,
        packageName: fresh.packageName,
        fingerprint: fingerprint,
        versionCode: fresh.versionCode,
        version: fresh.version,
      );
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['status'] == 'permission_required'
          ? 'Allow APK installation in Android settings, then try again'
          : response['status'] == 'installer_opened'
              ? 'Android installer opened. Confirm there; status refreshes on return.'
              : 'Installer returned: ${response['status'] ?? 'unknown'}')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Verified APK installation blocked: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _uninstall(AniyomiExtensionInfo ext) async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Uninstall extension?'),
        content: Text('Remove ' + ext.name + ' from Android?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialog, false),
            child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialog, true),
            child: const Text('Continue')),
        ],
      ),
    );
    if (approved != true || !mounted) return;
    try {
      await AniyomiExtensionBridge.uninstallExtension(ext.packageName);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Confirm uninstall in Android')));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot open uninstaller: ' + error.toString())));
    }
  }

  Future<void> _reload() async {
    if (mounted) setState(() => _loadingCatalogs = true);
    try {
      final items = await _manager.repositories();
      if (!mounted) return;
      setState(() {
        _repos = items;
        _catalogs.removeWhere((key, _) => !items.any((repo) => repo.toString() == key));
        _errors.clear();
      });

      // Loading saved URLs is not enough: load their catalog content on every
      // visit, without requiring the user to tap the repository refresh icon.
      for (final repo in items) {
        try {
          final entries = await _manager.fetchExtensions(repo);
          if (!mounted) return;
          setState(() => _catalogs[repo.toString()] = entries);
        } catch (error) {
          if (!mounted) return;
          setState(() {
            _catalogs.remove(repo.toString());
            _errors[repo.toString()] = error.toString();
          });
        }
      }
    } catch (error) {
      if (mounted) {
        setState(() => _errors['local'] = 'Cannot read saved repositories: $error');
      }
    } finally {
      if (mounted) setState(() => _loadingCatalogs = false);
    }
  }

  Future<void> _add() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final candidate = await _manager.inspectRepository(_url.text);
      if (!mounted) return;
      final approved = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Trust extension repository?'),
          content: SelectableText('Repository: ${candidate.name}\n'
              'URL: ${candidate.indexUrl}\n\n'
              'Signing certificate SHA-256:\n${candidate.fingerprint}\n\n'
              'Installing an extension runs third-party code. '
              'Verify the fingerprint using an independent trusted source. '
              'Trust this repository only if you recognize its publisher.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel')),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Trust and save')),
          ],
        ),
      );
      if (approved != true) return;
      await _manager.trustRepository(candidate);
      _url.clear();
      await _reload();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Repository key trusted on this device')));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot add repository: $error')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _trustLegacy(Uri repo) async {
    _url.text = repo.toString();
    await _add();
  }

  Future<void> _load(Uri repo) async {
    setState(() {
      _errors.remove(repo.toString());
      _busy = true;
    });
    try {
      final entries = await _manager.fetchExtensions(repo);
      if (mounted) setState(() => _catalogs[repo.toString()] = entries);
      await _refreshInstalled();
    } catch (e) {
      if (mounted) setState(() => _errors[repo.toString()] = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove(Uri repo) async {
    await _manager.remove(repo);
    _catalogs.remove(repo.toString());
    _errors.remove(repo.toString());
    await _reload();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _url.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Extension repositories'),
        actions: [
          IconButton(
            tooltip: 'Refresh installed extensions',
            onPressed: _busy ? null : _refreshInstalled,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const Text('Add an Aniyomi-compatible index.min.json address, or '
          'paste an aniyomi://add-repo link. Addresses are stored locally. '
          'Only add extension repositories you trust.'),
        const SizedBox(height: 12),
        TextField(
          controller: _url,
          autocorrect: false,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
            labelText: 'Repository URL',
            hintText: 'https://example.org/repo/index.min.json',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => _add(),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: _busy ? null : _add,
            icon: const Icon(Icons.add),
            label: const Text('Add repository'),
          ),
        ),
        const Divider(),
        if (_repos.isEmpty)
          const ListTile(title: Text('No repositories added')),
        if (_loadingCatalogs)
          const LinearProgressIndicator(),
        if (_errors['local'] != null)
          ListTile(title: const Text('Repository storage error'),
            subtitle: Text(_errors['local']!)),
        // Repository management stays local and is separate from package removal.
        ExpansionTile(
          title: const Text('Repository management'),
          children: [
            for (final repo in _repos)
              ListTile(
                title: Text(repo.host),
                subtitle: Text(_errors[repo.toString()] ?? repo.toString(), maxLines: 2),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(
                    tooltip: 'Load catalog',
                    onPressed: _busy ? null : () => _load(repo),
                    icon: const Icon(Icons.refresh),
                  ),
                  IconButton(
                    tooltip: 'Remove repository',
                    onPressed: _busy ? null : () => _remove(repo),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ]),
              ),
          ],
        ),
        TextField(
          decoration: const InputDecoration(
            hintText: 'Search extensions',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (value) => setState(() => _search = value.trim().toLowerCase()),
        ),
        Wrap(spacing: 6, children: [
          for (final tab in [
            (0, 'Installed'),
            (1, 'Updates'),
            (2, 'Browse')
          ])
            ChoiceChip(
              label: Text(tab.$2),
              selected: _section == tab.$1,
              onSelected: (_) => setState(() => _section = tab.$1),
            ),
        ]),
        Builder(builder: (context) {
          final entries = <String, AniyomiCatalogEntry>{};
          final origins = <String, Uri>{};
          for (final repo in _repos) {
            for (final entry in _catalogs[repo.toString()] ?? <AniyomiCatalogEntry>[]) {
              final old = entries[entry.packageName];
              if (old == null || old.versionCode < entry.versionCode) {
                entries[entry.packageName] = entry;
                origins[entry.packageName] = repo;
              }
            }
          }
          final values = entries.values.toList()
            ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
          final langs = <String>{'all', ...values.map((e) => e.language)};
          if (!langs.contains(_language)) _language = 'all';
          final matching = values.where((entry) {
            final installed = _installed[entry.packageName];
            if (_section == 0 && installed == null) return false;
            if (_section == 1 &&
                (installed == null || installed.versionCode >= entry.versionCode)) return false;
            // Browse includes both installed and available extensions.
            if (_language != 'all' && entry.language != _language) return false;
            return (entry.name + entry.packageName + entry.language)
                .toLowerCase().contains(_search);
          }).toList();
          final sections = <String, List<AniyomiCatalogEntry>>{};
          for (final item in matching) {
            sections.putIfAbsent(item.language, () => []).add(item);
          }
          final keys = sections.keys.toList()..sort();
          final extraInstalled = _section == 0
              ? _installed.values.where((e) => !entries.containsKey(e.packageName) &&
                  (e.name + e.packageName).toLowerCase().contains(_search)).toList()
              : <AniyomiExtensionInfo>[];
          extraInstalled.sort((a, b) => a.name.compareTo(b.name));
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            DropdownButton<String>(
              isExpanded: true,
              value: _language,
              items: (langs.toList()..sort()).map((code) => DropdownMenuItem(
                value: code,
                child: Text(code == 'all' ? 'All languages' : code.toUpperCase()),
              )).toList(),
              onChanged: (value) => setState(() => _language = value ?? 'all'),
            ),
            for (final lang in keys) ...[
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Text(lang == 'all' ? 'All languages' : lang.toUpperCase(),
                  style: Theme.of(context).textTheme.titleMedium),
              ),
              for (final entry in sections[lang]!)
                ListTile(
                  leading: Image.network(entry.iconUrl.toString(),
                    width: 38, height: 38,
                    errorBuilder: (_, __, ___) => const Icon(Icons.extension_outlined)),
                  title: Text(entry.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(
                    'v' + entry.version +
                    (_installed[entry.packageName] != null
                      ? ' • Installed v' + _installed[entry.packageName]!.version
                      : ''),
                  ),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    if (_installed[entry.packageName] == null ||
                        _installed[entry.packageName]!.versionCode < entry.versionCode)
                      IconButton(
                        tooltip: _installed[entry.packageName] == null ? 'Install' : 'Update',
                        icon: const Icon(Icons.download_outlined),
                        onPressed: _busy ? null : () => _install(entry, origins[entry.packageName]!),
                      ),
                    if (_installed[entry.packageName] != null)
                      PopupMenuButton<String>(
                        tooltip: 'Extension options',
                        onSelected: (value) {
                          if (value == 'uninstall') _uninstall(_installed[entry.packageName]!);
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'uninstall', child: Text('Uninstall')),
                        ],
                      ),
                  ]),
                ),
            ],
            if (extraInstalled.isNotEmpty) ...[
              const Padding(padding: EdgeInsets.only(top: 12),
                child: Text('Installed outside catalogs')),
              for (final ext in extraInstalled)
                ListTile(
                  title: Text(ext.name),
                  subtitle: Text('Installed v' + ext.version),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Uninstall',
                    onPressed: () => _uninstall(ext),
                  ),
                ),
            ],
            if (matching.isEmpty && extraInstalled.isEmpty && !_loadingCatalogs)
              ListTile(
                title: const Text('No matching extensions'),
                subtitle: Text(_catalogs.isEmpty
                  ? 'No catalogs loaded. Check repository management for errors.'
                  : 'Try another tab, language or search term.'),
              ),
          ]);
        }),
        const SizedBox(height: 12),
        const Text('APK signatures are verified against the locally approved certificate before Android is asked to install. Confirm installation in Android. Full Anikku Host API support is still in progress.'),
      ]),
    );
  }
}
