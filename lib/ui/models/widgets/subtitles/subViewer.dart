import 'dart:io';

import 'package:animestream/core/app/logging.dart';
import 'package:animestream/core/commons/enums.dart';
import 'package:animestream/core/commons/subtitleParsers/subtitleParsers.dart';
import 'package:animestream/ui/models/snackBar.dart';
import 'package:animestream/ui/models/playerControllers/videoController.dart';
import 'package:animestream/ui/models/widgets/subtitles/subtitle.dart';
import 'package:animestream/ui/models/widgets/subtitles/subtitleSettings.dart';
import 'package:animestream/ui/models/widgets/subtitles/subtitleText.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class SubViewer extends StatefulWidget {
  final VideoController controller;
  final String subtitleSource;
  final Map<String, String>? headers;
  final SubtitleFormat format;
  final SubtitleSettings settings;
  final bool isOffline;

  const SubViewer({
    super.key,
    required this.controller,
    required this.format,
    required this.subtitleSource,
    required this.settings,
    this.headers = const {},
    this.isOffline = false,
  });

  @override
  State<SubViewer> createState() => _SubViewerState();
}

class _SubViewerState extends State<SubViewer> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_updateSubtitle);
    loadSubs();
    print("[SUBVIEWER]: subs initialized");
  }

  List<SubtitleCue> subs = [];

  List<SubtitleCue> activeSubtitles = [];

  final Map<SubtitleCue, int> _cueColorSlots = {};
  int _nextCueColorSlot = 0;

  bool areSubsLoading = true;

  String? _loadedSubsUrl;

  void loadSubs() async {
    try {
      setState(() {
        areSubsLoading = true;
      });
      subs.clear(); // clear the old subs (if any)
      _cueColorSlots.clear();
      _nextCueColorSlot = 0;
      print("[SUBVIEWER]: Loading ${widget.format.name} subs");
      if (widget.isOffline) {
        subs = await Subtitleparsers().parseSubsFromFile(widget.subtitleSource, widget.format);
      } else {
        subs = await Subtitleparsers()
            .parseSubsFromUrl(widget.subtitleSource, widget.format, headers: widget.headers ?? {});
      }

      print("Loaded subs from: ${widget.subtitleSource}");
      _loadedSubsUrl = widget.subtitleSource; // for changing subs when episode changes
      setState(() {
        areSubsLoading = false;
      });
    } catch (err) {
      Logs.player.log(err.toString());
      SchedulerBinding.instance.addPostFrameCallback((dur) {
        floatingSnackBar("Couldnt load the subtitles!");
      });
      setState(() {
        areSubsLoading = false;
      });
    }
  }

  int lastLineIndex = 0;

  void _updateSubtitle() {
    final currentPosition = widget.controller.position;

    if (currentPosition == null || subs.isEmpty) return;

    if (_loadedSubsUrl != widget.subtitleSource && !areSubsLoading) {
      print("Subtitle Source Changed, Loading new subs..");
      return loadSubs();
    }

    // If we seeked backward (current time is before the last known start), reset hint.
    if (lastLineIndex >= subs.length ||
        (lastLineIndex > 0 && subs[lastLineIndex].start.inMilliseconds > currentPosition)) {
      lastLineIndex = 0; // reset to start for safety
    }

    // Move forward past any subtitles that are over
    while (lastLineIndex < subs.length && subs[lastLineIndex].end.inMilliseconds < currentPosition) {
      lastLineIndex++;
    }

    List<SubtitleCue> newMatches = [];

    // Start checking from our synced index.
    for (int i = lastLineIndex; i < subs.length; i++) {
      final sub = subs[i];

      // If we hit a subtitle that starts in the future, we can stop looking entirely.
      // Because the list is usually sorted, no subsequent subtitle can be active either.
      if (sub.start.inMilliseconds > currentPosition) {
        break;
      }

      // If we are here, the subtitle started before now.
      // We just need to check if it hasn't ended yet.
      if (sub.end.inMilliseconds >= currentPosition) {
        newMatches.add(sub);
      }
    }

    if (!_areSubtitleListsEqual(activeSubtitles, newMatches)) {
      if (mounted) {
        setState(() {
          activeSubtitles = newMatches;
        });
      }
    }
  }

  // Helper to compare lists efficiently
  bool _areSubtitleListsEqual(List<SubtitleCue> a, List<SubtitleCue> b) {
    if (a.length != b.length) return false;
    if (a.isEmpty && b.isEmpty) return true;

    // compare the start n end times of the first and last subtitles
    return a.first.start.inMilliseconds == b.first.start.inMilliseconds &&
        a.first.end.inMilliseconds == b.first.end.inMilliseconds &&
        a.last.start.inMilliseconds == b.last.start.inMilliseconds &&
        a.last.end.inMilliseconds == b.last.end.inMilliseconds;
  }

  //i tried to make it beautiful! okay???
  TextStyle subTextStyle() {
    return TextStyle(
      fontSize: (Platform.isWindows || Platform.isLinux) ? widget.settings.fontSize * 1.5 : widget.settings.fontSize,
      fontFamily: widget.settings.fontFamily ?? "Rubik",
      color: widget.settings.textColor,
      fontWeight: widget.settings.bold ? FontWeight.w700 : FontWeight.w500,
      // letterSpacing: -0.2,
      // wordSpacing: 1,
      fontFamilyFallback: ["Poppins"],
      // backgroundColor: widget.settings.backgroundColor.withValues(alpha: widget.settings.backgroundTransparency),
    );
  }

  bool _containsStandaloneStatusKeyword(SubtitleCue sub) {
    const keywords = <String>{
      'attack',
      'defense',
      'magic',
      'speed',
      'equipment',
      'skills',
      'skill tree',
      'skill points',
      'current stats',
    };

    return sub.dialogue
        .split('\n')
        .map((line) => line.trim().toLowerCase())
        .any(keywords.contains);
  }

  bool _isStatusCue(SubtitleCue sub, List<SubtitleCue> active) {
    final nearby = active.where((candidate) {
      return (candidate.start - sub.start).inMilliseconds.abs() <= 100;
    }).toList();

    // Dense near-simultaneous cue groups are treated as status/UI.
    if (nearby.length >= 5) {
      return true;
    }

    // Standalone status keywords can identify a smaller status block.
    // If any cue with the exact same start time contains one of these words
    // on a line by itself, move the whole timestamp group to the left.
    final sameTimestamp = active.where(
      (candidate) => candidate.start == sub.start,
    );
    return sameTimestamp.any(_containsStandaloneStatusKeyword);
  }

  Widget _subtitleWidget(
    SubtitleCue sub, {
    TextAlign textAlign = TextAlign.center,
    double fontScale = 1.0,
    Color? textColor,
    Color? strokeColor,
    Color? backgroundColor,
    double? backgroundTransparency,
  }) {
    final baseStyle = subTextStyle();
    return SubtitleText(
      text: areSubsLoading ? "Loading Subs" : sub.dialogue,
      style: baseStyle.copyWith(
        fontSize: (baseStyle.fontSize ?? widget.settings.fontSize) * fontScale,
        color: textColor ?? baseStyle.color,
      ),
      strokeColor: strokeColor ?? widget.settings.strokeColor,
      strokeWidth: widget.settings.strokeWidth,
      backgroundColor: backgroundColor ?? widget.settings.backgroundColor,
      backgroundTransparency:
          backgroundTransparency ?? widget.settings.backgroundTransparency,
      enableShadows: widget.settings.enableShadows,
      textAlign: textAlign,
    );
  }

  bool _isBottomAlignment(SubtitleAlignment alignment) {
    return alignment == SubtitleAlignment.bottomLeft ||
        alignment == SubtitleAlignment.bottomCenter ||
        alignment == SubtitleAlignment.bottomRight;
  }

  Color _bottomStackColor(int index) {
    switch (index % 4) {
      case 0:
        return Colors.white;
      case 1:
        return const Color(0xFF9E9E9E);
      case 2:
        return const Color(0xFFCCBF51);
      default:
        return const Color(0xFF53FB57);
    }
  }

  bool _bottomStackUsesBlackStroke(int index) {
    final slot = index % 4;
    return slot == 2 || slot == 3;
  }

  int _lockedCueColorIndex(SubtitleCue sub) {
    return _cueColorSlots.putIfAbsent(
      sub,
      () => _nextCueColorSlot++,
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusSubs =
        activeSubtitles.where((sub) => _isStatusCue(sub, activeSubtitles)).toList();
    final normalSubs =
        activeSubtitles.where((sub) => !statusSubs.contains(sub)).toList();

    statusSubs.sort((a, b) => a.start.compareTo(b.start));

    final Map<SubtitleAlignment, List<SubtitleCue>> normalGrouped = {};
    for (final sub in normalSubs) {
      normalGrouped.putIfAbsent(sub.alignment, () => []).add(sub);
    }
    for (final list in normalGrouped.values) {
      list.sort((a, b) => a.start.compareTo(b.start));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          fit: StackFit.expand,
          children: [
            ...normalGrouped.entries.map((group) {
              return Align(
                alignment: getLineAlignment(group.key),
                child: Container(
                  width: constraints.maxWidth / 1.4,
                  margin: EdgeInsets.only(
                    bottom: widget.settings.bottomMargin,
                    top: widget.settings.bottomMargin,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: group.value.asMap().entries.map((entry) {
                      final useStackColor =
                          widget.settings.enableCueColors &&
                              widget.format == SubtitleFormat.VTT &&
                              _isBottomAlignment(group.key);
                      final cueColorIndex = useStackColor
                          ? _lockedCueColorIndex(entry.value)
                          : 0;
                      final useBlackStroke = useStackColor &&
                          _bottomStackUsesBlackStroke(cueColorIndex);

                      return _subtitleWidget(
                        entry.value,
                        textColor: useStackColor
                            ? _bottomStackColor(cueColorIndex)
                            : null,
                        strokeColor:
                            useBlackStroke ? Colors.black : null,
                      );
                    }).toList(),
                  ),
                ),
              );
            }),

            if (statusSubs.isNotEmpty)
              Positioned(
                left: 24,
                top: constraints.maxHeight * 0.05,
                width: constraints.maxWidth * 0.62,
                height: constraints.maxHeight * 0.90,
                child: Align(
                  alignment: Alignment.topLeft,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.topLeft,
                    child: SizedBox(
                      width: constraints.maxWidth * 0.62,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: statusSubs
                            .map(
                              (sub) => SizedBox(
                                width: double.infinity,
                                child: _subtitleWidget(
                                  sub,
                                  textAlign: TextAlign.left,
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Alignment getLineAlignment(SubtitleAlignment alignment) {
    switch (alignment) {
      case SubtitleAlignment.topLeft:
        return Alignment.topLeft;
      case SubtitleAlignment.topCenter:
        return Alignment.topCenter;
      case SubtitleAlignment.topRight:
        return Alignment.topRight;
      case SubtitleAlignment.centerLeft:
        return Alignment.centerLeft;
      case SubtitleAlignment.center:
        return Alignment.center;
      case SubtitleAlignment.centerRight:
        return Alignment.centerRight;
      case SubtitleAlignment.bottomLeft:
        return Alignment.bottomLeft;
      case SubtitleAlignment.bottomCenter:
        return Alignment.bottomCenter;
      case SubtitleAlignment.bottomRight:
        return Alignment.bottomRight;
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateSubtitle);
    super.dispose();
  }
}
