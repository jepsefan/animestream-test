import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

/// Experimental motion smoothing preference shared by player controls.
enum AssSmoothingMode { off, automaticPositionInterpolation }

class AssMotionSmoothing {
  static const _box = 'ass_motion_smoothing';
  static const _key = 'mode';
  static final ValueNotifier<AssSmoothingMode> current =
      ValueNotifier(AssSmoothingMode.off);
  static bool _loaded = false;

  static Future<void> ensureLoaded() async {
    if (_loaded) return;
    final box = await Hive.openBox(_box);
    final value = box.get(_key, defaultValue: 0);
    current.value = value == 1
        ? AssSmoothingMode.automaticPositionInterpolation
        : AssSmoothingMode.off;
    _loaded = true;
  }

  static Future<void> save(AssSmoothingMode mode) async {
    final box = await Hive.openBox(_box);
    await box.put(_key, mode == AssSmoothingMode.off ? 0 : 1);
    _loaded = true;
    current.value = mode;
  }
}
