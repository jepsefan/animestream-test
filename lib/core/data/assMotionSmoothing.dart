import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

/// Experimental temporal smoothing of ASS playback position samples.
/// This does not interpolate individual libass glyphs or bitmap positions.
class AssMotionSmoothing {
  static const _boxName = 'ass_motion_smoothing';
  static const _enabledKey = 'enabled';
  static final ValueNotifier<bool> enabled = ValueNotifier<bool>(false);
  static bool _loaded = false;

  static Future<void> ensureLoaded() async {
    if (_loaded) return;
    final box = await Hive.openBox(_boxName);
    enabled.value = box.get(_enabledKey, defaultValue: false) == true;
    _loaded = true;
  }

  static Future<void> setEnabled(bool value) async {
    final box = await Hive.openBox(_boxName);
    await box.put(_enabledKey, value);
    _loaded = true;
    enabled.value = value;
  }
}
