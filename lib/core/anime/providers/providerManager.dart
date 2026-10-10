import 'dart:convert';

import 'package:animestream/core/anime/providers/providerDetails.dart';
import 'package:animestream/core/data/providers.dart';
import 'package:animestream/core/network/network.dart';

class ProviderManager {
  static const String _fileBaseUrl =
      "https://raw.githubusercontent.com/frostnova721/provins/master/lib/providers/";
  static const String _indexUrl =
      "https://raw.githubusercontent.com/frostnova721/provins/master/index.json";

  final _providersPreferences = ProvidersPreferences();

  Future<String?> getSavedProviderCode(String identifier) async =>
      (await _providersPreferences.getProvider(identifier))?.code;

  Future<List<ProviderDetails>> getSavedProviders() =>
      _providersPreferences.listAllProviders();

  Future<void> saveProvider(ProviderDetails provider) =>
      _providersPreferences.saveProvider(provider);

  Future<void> removeProvider(ProviderDetails provider) =>
      _providersPreferences.removeProvider(provider.identifier);

  Future<String?> fetchProviderCode(String identifier) async {
    if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(identifier)) {
      throw const FormatException('Invalid provider identifier');
    }
    final response = await get(Uri.parse('$_fileBaseUrl$identifier/$identifier.dart'));
    if (response.statusCode != 200) {
      throw Exception('Provider download failed: HTTP ${response.statusCode}');
    }
    if (response.body.trim().isEmpty) {
      throw const FormatException('Provider source is empty');
    }
    return response.body;
  }

  Future<List<ProviderDetails>> fetchProvidersRepo() async {
    final response = await get(Uri.parse(_indexUrl));
    if (response.statusCode != 200) {
      throw Exception('Provider repository unavailable: HTTP ${response.statusCode}');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw const FormatException('Expected a JSON list of providers');
    }
    return decoded.map((entry) =>
      ProviderDetails.fromMap(Map<String, dynamic>.from(entry as Map))).toList();
  }
}
