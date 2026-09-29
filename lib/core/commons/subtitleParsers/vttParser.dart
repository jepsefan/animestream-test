//GPT CODE!!!
import 'package:animestream/ui/models/widgets/subtitles/subtitle.dart';
import 'package:collection/collection.dart';

class VttRipper {
  List<SubtitleCue> parseVtt(String rawSource) {
    final lines = rawSource.replaceAll('\r\n', '\n').split('\n');
    final subtitles = <SubtitleCue>[];

    final dialogueLines = <String>[];
    Duration? start;
    Duration? end;
    SubtitleAlignment alignment = SubtitleAlignment.bottomCenter;

    void flushCue() {
      if (start != null && end != null && dialogueLines.isNotEmpty) {
        final cleanedDialogue = dialogueLines
            .map(_cleanDialogueLine)
            .where((line) => line.isNotEmpty)
            .join('\n')
            .trim();

        if (cleanedDialogue.isNotEmpty) {
          subtitles.add(
            SubtitleCue(
              start: start!,
              end: end!,
              dialogue: cleanedDialogue,
              alignment: alignment,
            ),
          );
        }
      }

      dialogueLines.clear();
      start = null;
      end = null;
      alignment = SubtitleAlignment.bottomCenter;
    }

    for (final rawLine in lines) {
      final line = rawLine;
      final trimmed = line.trim();

      if (trimmed.startsWith('WEBVTT')) {
        continue;
      }

      // A new timestamp is the reliable cue boundary. Do not flush on blank
      // lines because some VTT sources put continuation text under the same
      // timestamp.
      if (line.contains('-->')) {
        flushCue();

        final times = line.split('-->');
        if (times.length != 2) {
          throw FormatException('Invalid timestamp line: $line');
        }

        final formatting = times[1].trim().split(RegExp(r'\s+'));
        final position =
            formatting.firstWhereOrNull((e) => e.startsWith('line:'))?.replaceAll(RegExp(r'line:|%'), '');

        alignment = position != null
            ? (int.tryParse(position) ?? 100) > 50
                ? SubtitleAlignment.bottomCenter
                : SubtitleAlignment.topCenter
            : SubtitleAlignment.bottomCenter;

        start = _parseTime(times[0].trim());
        end = _parseTime(formatting[0].trim());
        continue;
      }

      if (start == null || end == null) {
        continue;
      }

      if (trimmed.startsWith('NOTE')) {
        continue;
      }

      // Empty source lines should not create vertical gaps in status/UI text.
      if (trimmed.isEmpty) {
        continue;
      }

      // Some converted VTT files contain ASS/SSA vector drawing commands.
      // These describe shapes/backgrounds and must not be displayed as text.
      if (_isAssDrawingLine(trimmed)) {
        continue;
      }

      final cleanedLine = _cleanDialogueLine(line);
      if (cleanedLine.isEmpty) {
        continue;
      }

      dialogueLines.add(cleanedLine);
    }

    flushCue();
    return subtitles;
  }

  bool _isAssDrawingLine(String line) {
    return RegExp(
      r'^[mMnNlLbBsSpPcC](?:\s+-?\d+(?:\.\d+)?){2,}(?:\s+.*)?$',
    ).hasMatch(line);
  }

  String _cleanDialogueLine(String line) {
    return _removeHtml(
      line.replaceAll(RegExp(r'(?:\\h)+'), ' '),
    ).trim();
  }

  String _removeHtml(String dialogue) {
    final tagRegExp = RegExp(r'<[^>]*>');
    return dialogue.replaceAll(tagRegExp, '');
  }

  Duration _parseTime(String time) {
    final parts = time.split(':');
    if (parts.length == 3) {
      return Duration(
        hours: int.parse(parts[0]),
        minutes: int.parse(parts[1]),
        milliseconds: (double.parse(parts[2]) * 1000).round(),
      );
    } else if (parts.length == 2) {
      return Duration(
        minutes: int.parse(parts[0]),
        milliseconds: (double.parse(parts[1]) * 1000).round(),
      );
    }
    throw FormatException('Invalid time format: $time');
  }
}
