import 'package:animestream/core/app/logging.dart';
import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/commons/enums/hiveEnums.dart';
import 'package:animestream/core/data/types.dart';
import 'package:hive/hive.dart';

class Settings {
  static final String _boxName = HiveBox.animestream.boxName;

  Future<SettingsModal> getSettings({bool writing = false}) async {
    var box = await Hive.openBox(_boxName);
    if (!box.isOpen) box = await Hive.openBox(_boxName);
    Map<dynamic, dynamic> settings = await box.get(HiveKey.settings.name) ?? {};
    if (settings.isEmpty) settings = SettingsModal().toMap();

    final migrationDone =
        settings['preferredQualityDefault1080Migrated'] == true;
    if (!migrationDone) {
      final quality = settings['preferredQuality'];
      if (quality == null || quality == '720p') {
        settings['preferredQuality'] = '1080p';
      }
      settings['preferredQualityDefault1080Migrated'] = true;
      await box.put(HiveKey.settings.name, settings);
    }

    final classed = SettingsModal.fromMap(settings);
    if (!writing) await box.close();
    return classed;
  }

  Future<void> writeSettings(SettingsModal settings) async {
    var box = await Hive.openBox(_boxName);
    if (!box.isOpen) box = await Hive.openBox(_boxName);
    var currentSettings = (await getSettings(writing: true)).toMap();
    var updatedSettings = settings.toMap();
    Logs.app.log("before updation: $currentSettings");
    Logs.app.log("value upation: $updatedSettings");
    currentSettings.forEach((key, value) {
      if (updatedSettings[key] != null) {
        currentSettings[key] = updatedSettings[key];
      }
    });
    currentUserSettings = SettingsModal.fromMap(currentSettings);
    await box.put(HiveKey.settings.name, currentSettings);
    if (box.isOpen) await box.close;
  }
}
