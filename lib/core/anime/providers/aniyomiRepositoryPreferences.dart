import 'package:animestream/core/anime/providers/aniyomiRepository.dart';
import 'package:animestream/core/commons/enums/hiveEnums.dart';
import 'package:hive/hive.dart';

/// Stores the user's selected AniYomi repository URL only on this device.
class AniyomiRepositoryPreferences {
  static const String _urlKey = 'index_url';
  final String _boxName = HiveBox.animeExtensionSettings.boxName;

  Future<String?> getIndexUrl() async {
    final box = await Hive.openBox(_boxName);
    final value = box.get(_urlKey);
    if (value is! String || value.trim().isEmpty) return null;
    return value;
  }

  Future<void> saveIndexUrl(String value) async {
    final normalized = AniyomiRepository.normalizeIndexUrl(value);
    final box = await Hive.openBox(_boxName);
    await box.put(_urlKey, normalized);
  }

  Future<void> clearIndexUrl() async {
    final box = await Hive.openBox(_boxName);
    await box.delete(_urlKey);
  }
}
