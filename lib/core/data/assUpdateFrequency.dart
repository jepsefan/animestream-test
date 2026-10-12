import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

/// ASS render cap. Zero follows Flutter's display vsync.
class AssUpdateFrequency {
  static const String _boxName = 'ass_update_frequency';
  static const String _key = 'fps';
  static const List<int> choices = [0, 24, 30, 60, 120];
  static final ValueNotifier<int> current = ValueNotifier<int>(0);
  static bool _loaded = false;

  static Future<int> load() async {
    final box = await Hive.openBox(_boxName);
    final value = box.get(_key, defaultValue: 0);
    final fps = value is int && (value == 0 || value >= 1 && value <= 120)
        ? value
        : 0;
    current.value = fps;
    _loaded = true;
    return fps;
  }

  static Future<void> save(int fps) async {
    if (fps != 0 && (fps < 1 || fps > 120)) {
      throw ArgumentError.value(fps, 'fps', 'ASS FPS must be Auto or 1–120');
    }
    final box = await Hive.openBox(_boxName);
    await box.put(_key, fps);
    _loaded = true;
    current.value = fps;
  }

  static Future<void> ensureLoaded() async {
    if (!_loaded) await load();
  }
}
