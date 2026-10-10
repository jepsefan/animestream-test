import 'package:animestream/core/anime/providers/providerDetails.dart';
import 'package:animestream/core/anime/providers/aniyomiExtensionBridge.dart';
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
                  Column(children: [
                    const Padding(padding: EdgeInsets.all(8), child: Text('Detected Android APK extensions (not loaded)')),
                    if (_apkExtensions.isEmpty)
                      const Padding(padding: EdgeInsets.all(8), child: Text('No installed Aniyomi APK extensions detected')),
                    for (final ext in _apkExtensions)
                      ListTile(title: Text(ext.name),
                        subtitle: Text('${ext.packageName} • v${ext.version} • Detected, not executable yet'\n                          '${ext.sourceClass != null ? "\\nSource class: ${ext.sourceClass}" : ""}'\n                          '${ext.sourceFactory != null ? "\\nSource factory: ${ext.sourceFactory}" : ""}')),
                    const Divider(),
                    Expanded(child: _items(_installed, installed: true)),
                  ]),
                  _items(_available, installed: false),
                ])),
        ]),
      ),
    );
  }
}
