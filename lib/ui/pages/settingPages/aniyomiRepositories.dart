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

  Future<void> _reload() async {
    final items = await _manager.repositories();
    if (mounted) setState(() => _repos = items);
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
        for (final repo in _repos)
          FutureBuilder<String?>(
            future: _manager.trustedFingerprint(repo),
            builder: (context, snapshot) => ExpansionTile(
            key: ValueKey(repo.toString()),
            title: Text(repo.host),
            subtitle: Text(repo.toString() +
                (snapshot.data == null ? ' • Untrusted (reapprove)' : ' • Trusted')),
            children: [
              Wrap(spacing: 8, children: [
                if (snapshot.data == null)
                  TextButton.icon(
                    onPressed: _busy ? null : () => _trustLegacy(repo),
                    icon: const Icon(Icons.verified_user_outlined),
                    label: const Text('Review signing key'),
                  ),
                TextButton.icon(
                  onPressed: _busy || snapshot.data == null ? null : () => _load(repo),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Browse catalog'),
                ),
                TextButton.icon(
                  onPressed: _busy ? null : () => _remove(repo),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Remove'),
                ),
              ]),
              if (_errors[repo.toString()] != null)
                SelectableText(_errors[repo.toString()]!),
              for (final entry in _catalogs[repo.toString()] ??
                  const <AniyomiCatalogEntry>[])
                ListTile(
                  title: Text(entry.name),
                  subtitle: Text(
                    '${entry.language} • catalog v${entry.version}\n'
                    '${_installed[entry.packageName] == null ? 'Not installed' : 'Installed v${_installed[entry.packageName]!.version}'}\n'
                    '${entry.sources.toSet().join(", ")}',
                  ),
                  isThreeLine: true,
                  trailing: _installed[entry.packageName] != null &&
                    _installed[entry.packageName]!.versionCode >= entry.versionCode
                      ? const Icon(Icons.check_circle_outline)
                      : TextButton(
                          onPressed: _busy ? null : () => _install(entry, repo),
                          child: Text(_installed.containsKey(entry.packageName)
                            ? 'Update' : 'Install'),
                        ),
                ),
            ],
          )),
        const SizedBox(height: 12),
        const Text('APK signatures are verified against the locally approved certificate before Android is asked to install. Confirm installation in Android. Full Anikku Host API support is still in progress.'),
      ]),
    );
  }
}
