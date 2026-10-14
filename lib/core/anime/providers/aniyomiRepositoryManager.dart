import 'dart:convert';

import 'package:animestream/core/network/network.dart';
import 'package:hive/hive.dart';

/// User-defined Aniyomi/Anikku extension repositories.
/// No repository address is embedded in the app.
class AniyomiRepositoryManager {
  static const _boxName = 'aniyomi_extension_repositories_v1';

  /// Accepts an HTTPS index URL, a base URL ending in /, or an
  /// aniyomi://add-repo?url=... deep link.
  static Uri parseIndexUrl(String input) {
    var value = input.trim();
    if (value.isEmpty) throw const FormatException('Enter a repository URL');
    final supplied = Uri.tryParse(value);
    if (supplied?.scheme == 'aniyomi' && supplied?.host == 'add-repo') {
      value = supplied!.queryParameters['url']?.trim() ?? '';
    }
    final uri = Uri.tryParse(value);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasFragment ||
        uri.hasQuery) {
      throw const FormatException('Repository URL must be a direct HTTPS address');
    }
    if (uri.pathSegments.any((part) => part == '..' || part == '.')) {
      throw const FormatException('Invalid repository path');
    }
    final index = uri.path.endsWith('index.min.json')
        ? uri
        : Uri.parse('${uri.toString().replaceFirst(RegExp(r"/?$"), "/")}index.min.json');
    if (!index.path.endsWith('/index.min.json')) {
      throw const FormatException('Expected an index.min.json URL');
    }
    return index;
  }

  Future<Box> _box() => Hive.openBox(_boxName);

  Future<List<Uri>> repositories() async {
    final box = await _box();
    return box.keys.whereType<String>()
        .map(Uri.tryParse).whereType<Uri>().toList()
      ..sort((a, b) => a.toString().compareTo(b.toString()));
  }

  Future<void> add(String input) async {
    final index = parseIndexUrl(input);
    // Validate before storing the address.
    await fetchExtensions(index);
    final box = await _box();
    await box.put(index.toString(), DateTime.now().toIso8601String());
  }

  Future<void> remove(Uri indexUrl) async {
    final box = await _box();
    await box.delete(indexUrl.toString());
  }

  Future<List<AniyomiCatalogEntry>> fetchExtensions(Uri indexUrl) async {
    if (indexUrl.scheme != 'https' || indexUrl.host.isEmpty) {
      throw const FormatException('Untrusted repository URL');
    }
    final response = await get(indexUrl).timeout(const Duration(seconds: 25));
    if (response.statusCode != 200) {
      throw StateError('Repository returned HTTP ${response.statusCode}');
    }
    if (response.body.length > 8 * 1024 * 1024) {
      throw const FormatException('Repository index is too large');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw const FormatException('Repository index must be a JSON array');
    }
    final entries = <AniyomiCatalogEntry>[];
    for (final raw in decoded) {
      if (raw is! Map) continue;
      try {
        entries.add(AniyomiCatalogEntry.fromJson(
          Map<String, dynamic>.from(raw), indexUrl));
      } on FormatException {
        // Skip malformed records without rejecting the whole catalogue.
      }
    }
    if (entries.isEmpty) {
      throw const FormatException('Repository has no valid extensions');
    }
    return entries;
  }
}

class AniyomiCatalogEntry {
  final String name;
  final String packageName;
  final String version;
  final int versionCode;
  final String language;
  final bool nsfw;
  final Uri apkUrl;
  final Uri iconUrl;
  final List<String> sources;

  const AniyomiCatalogEntry({
    required this.name,
    required this.packageName,
    required this.version,
    required this.versionCode,
    required this.language,
    required this.nsfw,
    required this.apkUrl,
    required this.iconUrl,
    required this.sources,
  });

  factory AniyomiCatalogEntry.fromJson(
      Map<String, dynamic> json, Uri indexUrl) {
    String field(String name) => (json[name] ?? '').toString().trim();
    final pkg = field('pkg');
    final apk = field('apk');
    if (!RegExp(r'^[a-zA-Z0-9_]+(?:\\.[a-zA-Z0-9_]+)+$').hasMatch(pkg) ||
        !RegExp(r'^[a-zA-Z0-9_.-]+\\.apk$').hasMatch(apk)) {
      throw const FormatException('Invalid extension package or APK filename');
    }
    final baseUrl = indexUrl.resolve('.');
    final sourceObjects = json['sources'];
    return AniyomiCatalogEntry(
      name: field('name').replaceFirst(RegExp(r'^Aniyomi:\\s*'), ''),
      packageName: pkg,
      version: field('version'),
      versionCode: int.tryParse(field('code')) ?? 0,
      language: field('lang'),
      nsfw: field('nsfw') == '1',
      apkUrl: baseUrl.resolve('apk/${Uri.encodeComponent(apk)}'),
      iconUrl: baseUrl.resolve('icon/${Uri.encodeComponent(pkg)}.png'),
      sources: sourceObjects is List
          ? sourceObjects.whereType<Map>().map((source) =>
              (source['name'] ?? '').toString()).where((s) => s.isNotEmpty)
              .toList()
          : const <String>[],
    );
  }
}
