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
        if (dialogueLines.isNotEmpty) {
          subtitles.add(
            SubtitleCue(
              start: start!,
              end: end!,
              dialogue: _removeHtml(
                dialogueLines.join('\n').replaceAll(r'\h', ' '),
              ),
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

      // A new timestamp is the reliable cue boundary. This intentionally does
      // not flush on blank lines because some VTT sources put status/UI text
      // such as Attack / Defense / Magic / Speed in blank-line-separated
      // continuation lines under one timestamp.
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

      // Ignore metadata outside a cue.
      if (start == null || end == null) {
        continue;
      }

      if (trimmed.startsWith('NOTE')) {
        continue;
      }

      // Empty source lines should not create huge vertical gaps in status/UI
      // text such as Attack / Defense / Magic / Speed.
      if (trimmed.isEmpty) {
        continue;
      }

      // Some converted VTT files contain ASS vector drawing commands. They
      // describe shapes/backgrounds and must not be shown as subtitle text.
      if (_isAssDrawingLine(trimmed)) {
        continue;
      }

      dialogueLines.add(line);
    }

    flushCue();
    return subtitles;
  }

  bool _isAssDrawingLine(String line) {
    return RegExp(r'^[mMnNlLbBsSpPcC](?:\\s+-?\\d+(?:\\.\\d+)?){2,}(?:\\s+.*)?
    final tagRegExp = RegExp(r'<[^>]*>');
    return dialogue.replaceAll(tagRegExp, "");
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
)
        .hasMatch(line);
  }

  String _removeHtml(String dialogue) {
    final tagRegExp = RegExp(r'<[^>]*>');
    return dialogue.replaceAll(tagRegExp, "");
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
