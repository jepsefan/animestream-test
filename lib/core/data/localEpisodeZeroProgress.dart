import 'package:animestream/core/commons/enums/hiveEnums.dart';
import 'package:hive/hive.dart';

/// Local-only completion for explicit Episode 0, shared across providers of
/// the same anime. This never updates AniList, MAL, SIMKL or ordinary progress.
class LocalEpisodeZeroProgress {
  static const String _key = 'localEpisodeZeroWatchedV1';

  static Future<bool> isWatched(int animeId) async {
    final box = await Hive.openBox(HiveBox.animeInfo.boxName);
    try {
      final saved = box.get(_key);
      return saved is Map && saved[animeId.toString()] == true;
    } finally {
      await box.close();
    }
  }

  static Future<void> markWatched(int animeId) async {
    final box = await Hive.openBox(HiveBox.animeInfo.boxName);
    try {
      final existing = box.get(_key);
      final saved = existing is Map
          ? Map<String, dynamic>.from(existing)
          : <String, dynamic>{};
      if (saved[animeId.toString()] == true) return;
      saved[animeId.toString()] = true;
      await box.put(_key, saved);
    } finally {
      await box.close();
    }
  }

  static Future<void> clearWatched(int animeId) async {
    final box = await Hive.openBox(HiveBox.animeInfo.boxName);
    try {
      final existing = box.get(_key);
      if (existing is! Map || !existing.containsKey(animeId.toString())) return;
      final saved = Map<String, dynamic>.from(existing);
      saved.remove(animeId.toString());
      await box.put(_key, saved);
    } finally {
      await box.close();
    }
  }
}
