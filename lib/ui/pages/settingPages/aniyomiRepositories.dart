import 'package:animestream/core/anime/providers/aniyomiRepositoryManager.dart';
import 'package:flutter/material.dart';

/// Browse user-added Aniyomi extension repositories without executing APKs.
class AniyomiRepositoriesPage extends StatefulWidget {
  const AniyomiRepositoriesPage({super.key});

  @override
  State<AniyomiRepositoriesPage> createState() =>
      _AniyomiRepositoriesPageState();
}

class _AniyomiRepositoriesPageState extends State<AniyomiRepositoriesPage> {
  final _manager = AniyomiRepositoryManager();
  final _url = TextEditingController();
  List<Uri> _repos = [];
  final Map<String, List<AniyomiCatalogEntry>> _catalogs = {};
  final Map<String, String> _errors = {};
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _reload();
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
    _url.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Extension repositories')),
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
                    '${entry.language} • v${entry.version} • '
                    '${entry.packageName}\n'
                    '${entry.sources.join(", ")}',
                  ),
                  isThreeLine: true,
                  trailing: const Tooltip(
                    message: 'APK installation not implemented yet',
                    child: Icon(Icons.info_outline),
                  ),
                ),
            ],
          )),
        const SizedBox(height: 12),
        const Text('The signing fingerprint is pinned locally after confirmation. '
          'Older saved repositories must be reapproved. '
          'This screen browses catalog metadata only. '
          'APK installation, signature verification, updates and full '
          'extension execution compatibility are not implemented here.'),
      ]),
    );
  }
}
