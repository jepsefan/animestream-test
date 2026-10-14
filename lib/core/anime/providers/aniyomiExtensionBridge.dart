import 'package:flutter/services.dart';

/// Bridge to installed Android Aniyomi extension APKs.
class AniyomiExtensionBridge {
  static const MethodChannel _channel =
      MethodChannel('animestream.app/aniyomi_extensions');

  /// Inspect local host API only; does not execute any installed extensions.
  static Future<Map<String, dynamic>> inspectHostAbi() async {
    final raw = await _channel.invokeMethod<Map<dynamic, dynamic>>('inspectHostAbi');
    return Map<String, dynamic>.from(raw ?? const {});
  }

  static Future<Map<String, dynamic>> inspectExtensionClass(String packageName) async {
    final raw = await _channel.invokeMethod<Map<dynamic, dynamic>>(
      'inspectExtensionClass', {'packageName': packageName});
    return Map<String, dynamic>.from(raw ?? const {});
  }

  static Future<Map<String, dynamic>> testExtensionInstantiation(String packageName) async {
    final raw = await _channel.invokeMethod<Map<dynamic, dynamic>>(
      'testExtensionInstantiation', {'packageName': packageName});
    return Map<String, dynamic>.from(raw ?? const {});
  }

  static Future<List<AniyomiExtensionSourceInfo>> discoverSources(String packageName) async {
    final raw = await _channel.invokeMethod<Map<dynamic, dynamic>>(
      'discoverExtensionSources', {'packageName': packageName});
    if (raw?['status'] != 'ok') throw StateError('Source discovery failed');
    return ((raw?['sources'] as List?) ?? const []).whereType<Map>()
        .map((item) => AniyomiExtensionSourceInfo.fromMap(item)).toList();
  }
  /// Runs an installed extension's search code only after explicit user consent.
  static Future<Map<String, dynamic>> testExtensionSearch(
      String packageName, String query, {int? sourceId}) async {
    final raw = await _channel.invokeMethod<Map<dynamic, dynamic>>(
      'testExtensionSearch', {'packageName': packageName, 'query': query, 'sourceId': sourceId});
    return Map<String, dynamic>.from(raw ?? const {});
  }

  /// Loads episode metadata for one user-selected extension search result.
  static Future<Map<String, dynamic>> testExtensionEpisodes(
      String packageName, String sourceUrl, String sourceTitle, {int? sourceId}) async {
    final raw = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'testExtensionEpisodes', {
      'packageName': packageName,
      'sourceUrl': sourceUrl,
      'sourceTitle': sourceTitle,
      'sourceId': sourceId,
    });
    return Map<String, dynamic>.from(raw ?? const {});
  }

  /// Opt-in stream resolution for a selected episode. Returns sanitized metadata.
  /// No media URL, signed query parameters or authorization headers are exposed.
  static Future<Map<String, dynamic>> testExtensionStreams(
      String packageName, String episodeUrl, String episodeName, {int? sourceId}) async {
    final raw = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'testExtensionStreams', {
      'packageName': packageName,
      'episodeUrl': episodeUrl,
      'episodeName': episodeName,
      'sourceId': sourceId,
    });
    return Map<String, dynamic>.from(raw ?? const {});
  }

  /// Return the streams for an explicitly selected episode to the player.
  /// The response can contain credentials in media URLs and headers. Never log it.
  static Future<Map<String, dynamic>> resolveExtensionStreams(
      String packageName, String episodeUrl, String episodeName, {int? sourceId}) async {
    final raw = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'resolveExtensionStreams', {
      'packageName': packageName,
      'episodeUrl': episodeUrl,
      'episodeName': episodeName,
      'sourceId': sourceId,
    });
    return Map<String, dynamic>.from(raw ?? const {});
  }

  static Future<List<AniyomiExtensionInfo>> listInstalledExtensions() async {
    final raw = await _channel.invokeMethod<List<dynamic>>('listInstalledExtensions');
    return (raw ?? const <dynamic>[])
        .map((item) => AniyomiExtensionInfo.fromMap(Map<String, dynamic>.from(item as Map)))
        .toList();
  }
}

class AniyomiExtensionInfo {
  final String packageName;
  final String name;
  final String version;
  final String? sourceClass;
  final String? sourceFactory;

  const AniyomiExtensionInfo({
    required this.packageName,
    required this.name,
    required this.version,
    this.sourceClass,
    this.sourceFactory,
  });

  factory AniyomiExtensionInfo.fromMap(Map<String, dynamic> map) =>
      AniyomiExtensionInfo(
        packageName: map['packageName'] as String,
        name: map['name'] as String,
        version: map['version'] as String,
        sourceClass: map['sourceClass'] as String?,
        sourceFactory: map['sourceFactory'] as String?,
      );
}

class AniyomiExtensionSourceInfo {
  final int id;
  final String name;
  final String language;
  const AniyomiExtensionSourceInfo(this.id, this.name, this.language);
  factory AniyomiExtensionSourceInfo.fromMap(Map<dynamic, dynamic> map) =>
    AniyomiExtensionSourceInfo((map['id'] as num).toInt(),
      map['name']?.toString() ?? 'Unnamed',
      map['language']?.toString() ?? '');
}
