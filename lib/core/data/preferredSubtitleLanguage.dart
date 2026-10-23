import 'package:hive/hive.dart';

/// Preferred language for source-provided subtitles. Separate from cross-source
/// ASS matching; setting survives app restarts and applies to all extensions.
class PreferredSubtitleLanguage {
  static const _box = 'animestream_subtitle_languages_v1';
  static const _key = 'source_tracks';
  static const values = <String>['auto', 'sv', 'en', 'ja', 'de', 'fr', 'es', 'ar', 'zh', 'ko', 'pt', 'it'];

  static Future<String> load() async {
    final box = await Hive.openBox(_box);
    final value = box.get(_key, defaultValue: 'en')?.toString() ?? 'en';
    return values.contains(value) ? value : 'en';
  }

  static Future<void> save(String language) async {
    if (!values.contains(language)) return;
    final box = await Hive.openBox(_box);
    await box.put(_key, language);
  }

  static String normalize(String value) {
    final language = value.trim().toLowerCase();
    if (RegExp(r'^(english|eng|en)([^a-z]|$)').hasMatch(language)) return 'en';
    if (RegExp(r'^(swedish|swe|sv)([^a-z]|$)').hasMatch(language)) return 'sv';
    if (RegExp(r'^(japanese|jpn|jp|ja)([^a-z]|$)').hasMatch(language)) return 'ja';
    if (RegExp(r'^(arabic|ara|ar)([^a-z]|$)').hasMatch(language)) return 'ar';
    if (RegExp(r'^(french|fra|fre|fr)([^a-z]|$)').hasMatch(language)) return 'fr';
    if (RegExp(r'^(german|deu|ger|de)([^a-z]|$)').hasMatch(language)) return 'de';
    if (RegExp(r'^(spanish|spa|es)([^a-z]|$)').hasMatch(language)) return 'es';
    if (RegExp(r'^(chinese|zho|chi|zh)([^a-z]|$)').hasMatch(language)) return 'zh';
    if (RegExp(r'^(korean|kor|ko)([^a-z]|$)').hasMatch(language)) return 'ko';
    if (RegExp(r'^(portuguese|por|pt)([^a-z]|$)').hasMatch(language)) return 'pt';
    if (RegExp(r'^(italian|ita|it)([^a-z]|$)').hasMatch(language)) return 'it';
    return language.split(RegExp(r'[^a-z]')).first;
  }
}
