import 'package:hive/hive.dart';

/// Frame-rate cap for animated ASS overlays. 0 follows Flutter's vsync.
class AssUpdateFrequency {
  static const String _boxName = 'ass_update_frequency';
  static const String _key = 'fps';
  static const List<int> choices = [0, 24, 30, 60, 120];

  static Future<int> load() async {
    final box = await Hive.openBox(_boxName);
    final value = box.get(_key, defaultValue: 0);
    return value is int && choices.contains(value) ? value : 0;
  }

  static Future<void> save(int fps) async {
    if (!choices.contains(fps)) {
      throw ArgumentError.value(fps, 'fps', 'Unsupported ASS frame rate');
    }
    final box = await Hive.openBox(_boxName);
    await box.put(_key, fps);
  }
}
