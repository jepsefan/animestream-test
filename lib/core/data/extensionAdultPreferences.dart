import 'dart:io';
import 'package:animestream/core/anime/providers/aniyomiExtensionBridge.dart';
import 'package:animestream/ui/models/sources.dart';

/// Change only explicit, boolean adult-content settings exposed by already
/// approved extension sources. Never guess a setting name or domain.
class ExtensionAdultPreferences {
  static final _adultName = RegExp(
    r'(^|[^a-z0-9])(nsfw|18[+]|adult|hentai|mature)([^a-z0-9]|$)',
    caseSensitive: false,
  );

  static bool isAdultSwitch(Map<String, dynamic> preference) {
    if (preference['type'] != 'boolean') return false;
    final title = preference['title']?.toString() ?? '';
    final key = preference['key']?.toString() ?? '';
    final normalized = '$title $key'.toLowerCase();
    if (RegExp(r'\b(hide|exclude|block|disable|filter)\b').hasMatch(normalized)) return false;
    return _adultName.hasMatch(title) || _adultName.hasMatch(key);
  }

  static Future<void> sync(bool enabled) async {
    if (!Platform.isAndroid) return;
    final manager = SourceManager.instance;
    final installed = await AniyomiExtensionBridge.listInstalledExtensions();
    for (final ext in installed) {
      for (final source in manager.approvedSourcesForExtension(ext.packageName)) {
        try {
          final response = await AniyomiExtensionBridge.listSourcePreferences(
              ext.packageName, source.id,
              sourceName: source.name, sourceLanguage: source.language);
          if (response['status'] != 'ok') continue;
          for (final raw in (response['preferences'] as List?) ?? const []) {
            if (raw is! Map) continue;
            final setting = Map<String, dynamic>.from(raw);
            if (!isAdultSwitch(setting) || setting['value'] == enabled) continue;
            await AniyomiExtensionBridge.updateSourcePreference(
              ext.packageName, source.id, setting['key'].toString(), enabled,
              sourceName: source.name, sourceLanguage: source.language);
          }
        } catch (_) {
          // A single incompatible source must not block other sources.
        }
      }
    }
  }
}
