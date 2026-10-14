import 'dart:convert';
import 'package:animestream/core/network/network.dart';
import 'package:hive/hive.dart';

/// Repositories and trusted signing-key fingerprints are stored locally.
class AniyomiRepositoryManager {
  static const _boxName = 'aniyomi_extension_repositories_v1';
  static final _sha256 = RegExp(r'^[a-f0-9]{64}$');

  static Uri parseIndexUrl(String input) {
    var value = input.trim();
    if (value.isEmpty) throw const FormatException('Enter a repository URL');
    final supplied = Uri.tryParse(value);
    if (supplied?.scheme == 'aniyomi' && supplied?.host == 'add-repo') {
      value = supplied!.queryParameters['url']?.trim() ?? '';
    }
    final uri = Uri.tryParse(value);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty ||
        uri.userInfo.isNotEmpty || uri.hasQuery || uri.hasFragment) {
      throw const FormatException('Repository must be a direct HTTPS URL');
    }
    final index = uri.path.endsWith('/index.min.json')
        ? uri
        : Uri.parse(uri.toString().replaceFirst(RegExp(r'/?$'), '/') + 'index.min.json');
    if (!index.path.endsWith('/index.min.json')) {
      throw const FormatException('Expected index.min.json');
    }
    return index;
  }

  Future<Box> _box() => Hive.openBox(_boxName);

  Future<List<Uri>> repositories() async {
    final box = await _box();
    final urls = box.keys.whereType<String>()
        .map(Uri.tryParse).whereType<Uri>().toList();
    urls.sort((a, b) => a.toString().compareTo(b.toString()));
    return urls;
  }

  /// Legacy beta34.23 records intentionally remain untrusted until approved.
  Future<String?> trustedFingerprint(Uri indexUrl) async {
    final box = await _box();
    final record = box.get(indexUrl.toString());
    if (record is! Map) return null;
    final key = (record['fingerprint'] ?? '').toString().toLowerCase();
    return _sha256.hasMatch(key) ? key : null;
  }

  Future<AniyomiRepositoryInfo> inspectRepository(String input) async {
    final index = parseIndexUrl(input);
    final data = await _json(index.resolve('repo.json'), 256 * 1024);
    if (data is! Map || data['meta'] is! Map) {
      throw const FormatException('Missing repo.json meta');
    }
    final meta = Map<String, dynamic>.from(data['meta'] as Map);
    final name = (meta['name'] ?? '').toString().trim();
    final key = (meta['signingKeyFingerprint'] ?? '')
        .toString().replaceAll(':', '').toLowerCase();
    if (name.isEmpty || !_sha256.hasMatch(key)) {
      throw const FormatException('Invalid repository name or signing key');
    }
    return AniyomiRepositoryInfo(index, name, key);
  }

  /// Only call after explicit user confirmation of the fingerprint.
  Future<void> trustRepository(AniyomiRepositoryInfo approved) async {
    final now = await inspectRepository(approved.indexUrl.toString());
    if (now.fingerprint != approved.fingerprint) {
      throw StateError('Signing key changed during confirmation');
    }
    await _fetchIndex(now.indexUrl);
    final old = await trustedFingerprint(now.indexUrl);
    if (old != null && old != now.fingerprint) {
      throw StateError('Previously trusted signing key differs');
    }
    final box = await _box();
    await box.put(now.indexUrl.toString(), {
      'name': now.name,
      'fingerprint': now.fingerprint,
      'trustedAt': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<void> remove(Uri indexUrl) async {
    final box = await _box();
    await box.delete(indexUrl.toString());
  }

  Future<List<AniyomiCatalogEntry>> fetchExtensions(Uri indexUrl) async {
    final trusted = await trustedFingerprint(indexUrl);
    if (trusted == null) {
      throw StateError('Please approve the repository signing key first');
    }
    final current = await inspectRepository(indexUrl.toString());
    if (current.fingerprint != trusted) {
      throw StateError('Repository signing key changed. Access blocked.');
    }
    return _fetchIndex(indexUrl);
  }

  Future<List<AniyomiCatalogEntry>> _fetchIndex(Uri indexUrl) async {
    final data = await _json(indexUrl, 8 * 1024 * 1024);
    if (data is! List) {
      throw const FormatException('Expected a JSON index array');
    }
    final entries = <AniyomiCatalogEntry>[];
    for (final raw in data) {
      if (raw is! Map) continue;
      try {
        entries.add(AniyomiCatalogEntry.fromJson(
            Map<String, dynamic>.from(raw), indexUrl));
      } on FormatException {
        // Skip malformed catalog entries.
      }
    }
    if (entries.isEmpty) {
      throw const FormatException('Repository has no valid extensions');
    }
    return entries;
  }

  Future<dynamic> _json(Uri url, int limit) async {
    if (url.scheme != 'https' || url.host.isEmpty) {
      throw const FormatException('HTTPS required');
    }
    final response = await get(url).timeout(const Duration(seconds: 25));
    if (response.statusCode != 200) {
      throw StateError('Repository HTTP ' + response.statusCode.toString());
    }
    if (response.bodyBytes.length > limit) {
      throw const FormatException('Repository response too large');
    }
    final target = response.request?.url;
    if (target != null && (target.scheme != 'https' || target.host != url.host)) {
      throw const FormatException('Cross-host redirect blocked');
    }
    return jsonDecode(response.body);
  }
}

class AniyomiRepositoryInfo {
  final Uri indexUrl;
  final String name;
  final String fingerprint;
  const AniyomiRepositoryInfo(this.indexUrl, this.name, this.fingerprint);
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

  factory AniyomiCatalogEntry.fromJson(Map<String, dynamic> json, Uri indexUrl) {
    String field(String name) => (json[name] ?? '').toString().trim();
    final pkg = field('pkg');
    final apk = field('apk');
    if (!RegExp(r'^[a-zA-Z0-9_]+(?:\.[a-zA-Z0-9_]+)+$').hasMatch(pkg) ||
        !RegExp(r'^[a-zA-Z0-9_.-]+\.apk$').hasMatch(apk)) {
      throw const FormatException('Invalid extension package or APK filename');
    }
    final base = indexUrl.resolve('.');
    final rawSources = json['sources'];
    return AniyomiCatalogEntry(
      name: field('name').replaceFirst(RegExp(r'^Aniyomi:\s*'), ''),
      packageName: pkg,
      version: field('version'),
      versionCode: int.tryParse(field('code')) ?? 0,
      language: field('lang'),
      nsfw: field('nsfw') == '1',
      apkUrl: base.resolve('apk/' + Uri.encodeComponent(apk)),
      iconUrl: base.resolve('icon/' + Uri.encodeComponent(pkg) + '.png'),
      sources: rawSources is List
          ? rawSources.whereType<Map>().map((s) => (s['name'] ?? '').toString())
              .where((s) => s.isNotEmpty).toList()
          : const <String>[],
    );
  }
}
