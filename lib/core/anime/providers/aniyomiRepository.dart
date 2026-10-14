import 'dart:convert';
import 'dart:io';

import 'package:animestream/core/network/network.dart';
import 'package:path_provider/path_provider.dart';

/// A source package listed in an Aniyomi-compatible extension repository.
class AniyomiRepositoryExtension {
  final String name;
  final String packageName;
  final String apk;
  final String version;
  final int nsfw;
  final List<AniyomiRepositorySource> sources;

  const AniyomiRepositoryExtension({
    required this.name,
    required this.packageName,
    required this.apk,
    required this.version,
    required this.nsfw,
    required this.sources,
  });

  factory AniyomiRepositoryExtension.fromMap(Map<String, dynamic> map) {
    final apk = map['apk'];
    final packageName = map['pkg'];
    if (apk is! String ||
        !RegExp(r'^[A-Za-z0-9._-]+\.apk$').hasMatch(apk) ||
        packageName is! String ||
        !RegExp(r'^[A-Za-z0-9._]+$').hasMatch(packageName)) {
      throw const FormatException('Invalid extension package entry');
    }
    final rawSources = map['sources'];
    return AniyomiRepositoryExtension(
      name: map['name'] as String? ?? packageName,
      packageName: packageName,
      apk: apk,
      version: map['version']?.toString() ?? '',
      nsfw: map['nsfw'] is num ? (map['nsfw'] as num).toInt() : 0,
      sources: rawSources is List
          ? rawSources
              .whereType<Map>()
              .map((source) => AniyomiRepositorySource.fromMap(
                  Map<String, dynamic>.from(source)))
              .toList(growable: false)
          : const [],
    );
  }

  String get languageLabel {
    final languages = sources
        .map((source) => source.language)
        .where((language) => language.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return languages.isEmpty ? 'Language unspecified' : languages.join(', ');
  }

  String get sourceLabel => sources.map((source) => source.name).toSet().join(', ');
}

class AniyomiRepositorySource {
  final String name;
  final String language;
  final String? baseUrl;

  const AniyomiRepositorySource({
    required this.name,
    required this.language,
    this.baseUrl,
  });

  factory AniyomiRepositorySource.fromMap(Map<String, dynamic> map) =>
      AniyomiRepositorySource(
        name: map['name'] as String? ?? '',
        language: map['lang'] as String? ?? '',
        baseUrl: map['baseUrl'] as String?,
      );
}

class AniyomiRepository {
  final String indexUrl;
  const AniyomiRepository({required this.indexUrl});

  /// Accept either a direct HTTPS JSON index or an AniYomi add-repo deep link.
  static String normalizeIndexUrl(String input) {
    var value = input.trim();
    final uri = Uri.tryParse(value);
    if (uri == null) throw const FormatException('Enter a valid repository URL');
    if (uri.scheme == 'aniyomi' && uri.host == 'add-repo') {
      value = uri.queryParameters['url']?.trim() ?? '';
    }
    final index = Uri.tryParse(value);
    if (index == null ||
        index.scheme != 'https' ||
        index.host.isEmpty ||
        !index.path.toLowerCase().endsWith('.json')) {
      throw const FormatException('Repository must be an HTTPS JSON index URL');
    }
    return index.toString();
  }

  Future<List<AniyomiRepositoryExtension>> fetchExtensions() async {
    final response = await get(Uri.parse(indexUrl));
    if (response.statusCode != 200) {
      throw HttpException('Extension repository returned HTTP ${response.statusCode}');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw const FormatException('Expected a JSON list of extensions');
    }
    return decoded
        .whereType<Map>()
        .map((entry) => AniyomiRepositoryExtension.fromMap(
            Map<String, dynamic>.from(entry)))
        .toList(growable: false);
  }

  Uri apkUri(AniyomiRepositoryExtension extension) {
    final index = Uri.parse(indexUrl);
    final directory = index.path.substring(0, index.path.lastIndexOf('/'));
    return index.replace(path: '$directory/apk/${extension.apk}', query: null, fragment: null);
  }

  Future<File> downloadApk(AniyomiRepositoryExtension extension) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(apkUri(extension));
      final response = await request.close();
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException('APK download returned HTTP ${response.statusCode}');
      }
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/${extension.apk}');
      await response.pipe(file.openWrite());
      if (await file.length() == 0) {
        await file.delete();
        throw const FormatException('Downloaded APK is empty');
      }
      return file;
    } finally {
      client.close(force: true);
    }
  }
}
