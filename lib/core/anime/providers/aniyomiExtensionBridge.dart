import 'package:flutter/services.dart';

/// Experimental Android APK discovery. Does not execute extension code.
class AniyomiExtensionBridge {
  static const MethodChannel _channel =
      MethodChannel('animestream.app/aniyomi_extensions');

  static Future<Map<String, dynamic>> inspectExtensionClass(String packageName) async {
    final raw = await _channel.invokeMethod<Map<dynamic, dynamic>>(
      'inspectExtensionClass', {'packageName': packageName});
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
