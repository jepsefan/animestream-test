import 'package:animestream/core/anime/providers/aniyomiExtensionBridge.dart';
import 'package:flutter/material.dart';

/// Shows only settings declared by an installed Aniyomi/Anikku source.
class ExtensionSourceSettingsPage extends StatefulWidget {
  final AniyomiExtensionInfo extension;
  const ExtensionSourceSettingsPage({super.key, required this.extension});

  @override
  State<ExtensionSourceSettingsPage> createState() => _ExtensionSourceSettingsPageState();
}

class _ExtensionSourceSettingsPageState extends State<ExtensionSourceSettingsPage> {
  List<AniyomiExtensionSourceInfo> _sources = [];
  AniyomiExtensionSourceInfo? _selected;
  List<Map<String, dynamic>> _preferences = [];
  bool _busy = true;
  String? _message;

  @override
  void initState() {
    super.initState();
    _loadSources();
  }

  Future<void> _loadSources() async {
    setState(() { _busy = true; _message = null; });
    try {
      final sources = await AniyomiExtensionBridge.discoverSources(widget.extension.packageName);
      if (!mounted) return;
      _sources = sources;
      _selected = sources.isEmpty ? null : sources.first;
      if (_selected == null) {
        setState(() { _busy = false; _message = 'No sources found in extension.'; });
      } else {
        await _loadPreferences();
      }
    } catch (error) {
      if (mounted) setState(() { _busy = false; _message = 'Could not load extension sources: $error'; });
    }
  }

  Future<void> _loadPreferences() async {
    final selected = _selected;
    if (selected == null) return;
    setState(() { _busy = true; _message = null; });
    try {
      final result = await AniyomiExtensionBridge.listSourcePreferences(
        widget.extension.packageName, selected.id,
        sourceName: selected.name, sourceLanguage: selected.language);
      if (!mounted || _selected?.id != selected.id) return;
      final status = result['status']?.toString();
      setState(() {
        _preferences = ((result['preferences'] as List?) ?? const [])
            .whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
        _message = status == 'unsupported'
            ? 'This source does not provide configurable settings.'
            : status == 'ok' && _preferences.isEmpty
                ? 'This source has no supported settings.'
                : status == 'ok' ? null : 'Unable to read settings: $status';
        _busy = false;
      });
    } catch (error) {
      if (mounted) setState(() { _busy = false; _message = 'Unable to read source settings: $error'; });
    }
  }

  Future<void> _save(Map<String, dynamic> item, Object value) async {
    final selected = _selected;
    if (_busy || selected == null) return;
    setState(() { _busy = true; _message = null; });
    try {
      final result = await AniyomiExtensionBridge.updateSourcePreference(
        widget.extension.packageName, selected.id, item['key'].toString(), value,
        sourceName: selected.name, sourceLanguage: selected.language);
      if (result['status'] != 'updated') {
        if (mounted) setState(() { _message = 'Source rejected setting: ${result['status']}'; _busy = false; });
        return;
      }
      await _loadPreferences();
    } catch (error) {
      if (mounted) setState(() { _busy = false; _message = 'Could not save setting: $error'; });
    }
  }

  Future<void> _editText(Map<String, dynamic> item) async {
    final controller = TextEditingController(text: item['value']?.toString() ?? '');
    final submitted = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item['title']?.toString() ?? 'Source setting'),
        content: TextField(
          controller: controller,
          maxLength: 256,
          autocorrect: false,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Save')),
        ],
      ),
    );
    controller.dispose();
    if (submitted != null && mounted) await _save(item, submitted);
  }

  Widget _option(Map<String, dynamic> item) {
    final title = item['title']?.toString() ?? item['key']?.toString() ?? 'Setting';
    final kind = item['type']?.toString();
    final values = (item['values'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final entries = (item['entries'] as List?)?.map((e) => e.toString()).toList() ?? [];
    if (kind == 'boolean') {
      return SwitchListTile(
        title: Text(title), value: item['value'] == true,
        onChanged: _busy ? null : (value) => _save(item, value),
      );
    }
    if (kind == 'list' && values.isNotEmpty && entries.length == values.length) {
      final current = item['value']?.toString();
      return ListTile(
        title: Text(title),
        subtitle: DropdownButton<String>(
          isExpanded: true,
          value: values.contains(current) ? current : null,
          hint: const Text('Select'),
          items: [for (var i = 0; i < values.length; i++)
            DropdownMenuItem(value: values[i], child: Text(entries[i], overflow: TextOverflow.ellipsis))],
          onChanged: _busy ? null : (value) { if (value != null) _save(item, value); },
        ),
      );
    }
    if (kind == 'multi_select' && values.length == entries.length) {
      final selected = (item['value'] as List?)?.map((v) => v.toString()).toSet() ?? <String>{};
      return ExpansionTile(
        title: Text(title),
        children: [for (var i = 0; i < values.length; i++)
          CheckboxListTile(
            title: Text(entries[i]), value: selected.contains(values[i]),
            onChanged: _busy ? null : (checked) {
              final next = {...selected};
              if (checked == true) { next.add(values[i]); } else { next.remove(values[i]); }
              _save(item, next.toList());
            },
          )],
      );
    }
    if (kind == 'text') {
      return ListTile(
        title: Text(title), subtitle: Text(item['value']?.toString() ?? ''),
        trailing: const Icon(Icons.edit_outlined),
        onTap: _busy ? null : () => _editText(item),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('${widget.extension.name} settings'),
      actions: [IconButton(
        tooltip: 'Refresh', icon: const Icon(Icons.refresh),
        onPressed: _busy ? null : _loadPreferences,
      )]),
    body: ListView(padding: const EdgeInsets.all(16), children: [
      const Text('Only settings provided by the installed extension are shown. Changes are stored locally and used when the source is reloaded.'),
      const SizedBox(height: 12),
      if (_sources.length > 1)
        DropdownButtonFormField<int>(
          value: _selected?.id,
          decoration: const InputDecoration(labelText: 'Extension source'),
          items: [for (final source in _sources)
            DropdownMenuItem(value: source.id, child: Text('${source.name} (${source.language})'))],
          onChanged: _busy ? null : (id) {
            if (id == null) return;
            _selected = _sources.firstWhere((source) => source.id == id);
            _loadPreferences();
          },
        ),
      if (_busy) const LinearProgressIndicator(),
      if (_message != null) ListTile(title: Text(_message!)),
      for (final item in _preferences) _option(item),
    ]),
  );
}
