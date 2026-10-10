import 'package:animestream/core/anime/providers/providerDetails.dart';
import 'package:animestream/core/commons/enums/hiveEnums.dart';
import 'package:hive/hive.dart';

class ProvidersPreferences {
  final _boxKey = HiveBox.animeProviders.boxName;

  Future<ProviderDetails?> getProvider(String identifier) async {
    final box = await Hive.openBox(_boxKey);
    final value = box.get(identifier);
    if (value is! Map) return null;
    return ProviderDetails.fromMap(Map<String, dynamic>.from(value));
  }

  Future<List<ProviderDetails>> listAllProviders() async {
    final box = await Hive.openBox(_boxKey);
    return box.values.whereType<Map>().map((value) =>
      ProviderDetails.fromMap(Map<String, dynamic>.from(value))).toList();
  }

  Future<void> saveProvider(ProviderDetails provider) async {
    final box = await Hive.openBox(_boxKey);
    await box.put(provider.identifier, provider.toMap());
  }

  Future<void> removeProvider(String identifier) async {
    final box = await Hive.openBox(_boxKey);
    await box.delete(identifier);
  }
}
