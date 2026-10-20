import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:animestream/core/data/assUpdateFrequency.dart';

import 'package:animestream/ui/models/playerControllers/videoController.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';

/// Optional libass overlay for external ASS/SSA files.
///
/// Uses the Android method channel instead of Better Player's subtitle pipeline.
/// The native AAR and channel must be registered before enabling this widget.
class ExternalAssOverlay extends StatefulWidget {
  const ExternalAssOverlay({
    super.key,
    required this.controller,
    required this.subtitleSource,
    this.headers = const {},
    this.isOffline = false,
    this.delayMs = 0,
  });

  final VideoController controller;
  final String subtitleSource;
  final Map<String, String> headers;
  final bool isOffline;
  final int delayMs;

  @override
  State<ExternalAssOverlay> createState() => _ExternalAssOverlayState();
}

class _ExternalAssOverlayState extends State<ExternalAssOverlay>
    with SingleTickerProviderStateMixin {
  static const _channel = MethodChannel('animestream.app/assrender');
  late final Ticker _frameTicker;
  int _lastIdlePollUs = 0;
  int _assFps = 0;
  int _lastCappedFrameUs = -1;
  final Stopwatch _playbackClock = Stopwatch();
  int? _clockAnchorPosition;
  int _clockAnchorElapsedMs = 0;
  int? _lastReportedPosition;
  bool _wasAdvancing = false;
  int _clockResyncs = 0;
  int _clockSeeks = 0;
  int _clockInterpolatedFrames = 0;
  int _clockStaleReports = 0;
  int _clockFreshReports = 0;
  int? _textureId;
  bool _ready = false;
  bool _rendering = false;
  int _generation = 0;
  int _lastPosition = -1;
  int _loadedGeneration = -1;
  final List<(int, int)> _cueTimes = [];
  int _lastDiagnosticSecond = -1;
  final Stopwatch _assStatsClock = Stopwatch();
  int _assTicks = 0;
  int _assRequests = 0;
  int _assUniquePositions = 0;
  int _assRepeatedPositions = 0;
  int _assBusyTicks = 0;
  int _assRenderTotalUs = 0;
  int _assRenderMaxUs = 0;
  int _assLastSamplePosition = -1;
  int _assLastTickElapsedUs = -1;
  int _assTickMaxGapUs = 0;

  @override
  void initState() {
    super.initState();
    _frameTicker = createTicker(_onFrame);
    AssUpdateFrequency.current.addListener(_onAssFpsChanged);
    AssUpdateFrequency.load().then((fps) {
      if (mounted) _assFps = fps;
    });
    _playbackClock.start();
    widget.controller.addListener(_onPlayerUpdate);
    _onPlayerUpdate();
    _load();
  }

  @override
  void didUpdateWidget(covariant ExternalAssOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onPlayerUpdate);
      widget.controller.addListener(_onPlayerUpdate);
      _clockAnchorPosition = null;
      _lastReportedPosition = null;
      _onPlayerUpdate();
    }
    if (oldWidget.subtitleSource != widget.subtitleSource ||
        oldWidget.isOffline != widget.isOffline ||
        oldWidget.headers.toString() != widget.headers.toString()) {
      _load();
    }
  }

  Future<void> _load() async {
    final generation = ++_generation;
    _frameTicker.stop();
    _ready = false;
    _textureId = null;
    _lastPosition = -1;
    _clockAnchorPosition = null;
    _lastReportedPosition = null;
    _wasAdvancing = false;
    _clockResyncs = _clockSeeks = _clockInterpolatedFrames = 0;
    _clockStaleReports = _clockFreshReports = 0;
    _cueTimes.clear();
    _lastDiagnosticSecond = -1;
    _assStatsClock.reset();
    _assTicks = _assRequests = _assUniquePositions = _assRepeatedPositions = _assBusyTicks = 0;
    _assRenderTotalUs = _assRenderMaxUs = 0;
    _assLastSamplePosition = _assLastTickElapsedUs = -1;
    _assTickMaxGapUs = 0;
    if (!Platform.isAndroid) return;

    try {
      final Uint8List bytes;
      if (widget.isOffline) {
        bytes = await File(widget.subtitleSource).readAsBytes();
      } else {
        final client = HttpClient();
        try {
          final request = await client.getUrl(Uri.parse(widget.subtitleSource));
          widget.headers.forEach(request.headers.set);
          final response = await request.close();
          if (response.statusCode < 200 || response.statusCode >= 300) {
            throw HttpException('ASS HTTP ${response.statusCode}');
          }
          final chunks = await response.fold<List<int>>(
            <int>[], (out, chunk) => out..addAll(chunk),
          );
          bytes = Uint8List.fromList(chunks);
        } finally {
          client.close(force: true);
        }
      }
      if (!mounted || generation != _generation) return;
      _inspectCueTimes(bytes);
      debugPrint('[ASSRENDER] Loading ${bytes.length} subtitle bytes');
      final textureId = await _channel.invokeMethod<int>('loadTexture', {
        'script': bytes,
        'width': 1280,
        'height': 720,
      });
      if (!mounted || generation != _generation) return;
      setState(() => _textureId = textureId);
      _loadedGeneration = generation;
      _ready = true;
      debugPrint('[ASSRENDER] Script loaded successfully');
      _lastIdlePollUs = 0;
      _assStatsClock.start();
      _frameTicker.start();
      _render();
    } catch (error) {
      debugPrint('[ASSRENDER] Native overlay unavailable: ${error.runtimeType}');
    }
  }

  // Keep a monotonic clock between player reports. A repeated position is
  // not a new sample: re-anchoring to it would freeze animated ASS drawings.
  void _onPlayerUpdate() {
    final reported = widget.controller.position;
    if (reported == null) return;
    final now = _playbackClock.elapsedMilliseconds;
    final advancing = widget.controller.isPlaying == true &&
        widget.controller.isBuffering != true;
    final previous = _lastReportedPosition;
    final fresh = previous == null || reported != previous;
    if (!fresh && advancing == _wasAdvancing) {
      _clockStaleReports++;
      return;
    }
    if (fresh) _clockFreshReports++;

    final predicted = _clockAnchorPosition == null
        ? reported
        : _clockAnchorPosition! + (_wasAdvancing ? now - _clockAnchorElapsedMs : 0);
    final difference = reported - predicted;
    final seek = fresh && previous != null &&
        (reported < previous - 150 || difference.abs() > 750);
    if (seek) _clockSeeks++;

    // On pause/buffering, use the latest actual player position; on resume,
    // start a new monotonic segment. Do not snap to repeated stale reports.
    if (_clockAnchorPosition == null || seek || advancing != _wasAdvancing ||
        (fresh && difference.abs() > 120)) {
      if (_clockAnchorPosition != null && !seek) _clockResyncs++;
      _clockAnchorPosition = reported;
      _clockAnchorElapsedMs = now;
    }
    _lastReportedPosition = reported;
    _wasAdvancing = advancing;
  }

  int? _rawAssPosition() {
    final reported = widget.controller.position;
    if (reported == null) return null;
    if (_clockAnchorPosition == null) _onPlayerUpdate();
    if (_clockAnchorPosition == null) return reported;
    final advancing = widget.controller.isPlaying == true &&
        widget.controller.isBuffering != true;
    if (advancing != _wasAdvancing) _onPlayerUpdate();
    if (!advancing) return _clockAnchorPosition;

    // No one-second cap: video can keep playing even if the platform stops
    // emitting position events. Seek and pause are handled by the listener.
    final now = _playbackClock.elapsedMilliseconds;
    final elapsed = (now - _clockAnchorElapsedMs).clamp(0, 1 << 53);
    final interpolated = _clockAnchorPosition! + elapsed;
    final duration = widget.controller.duration;
    _clockInterpolatedFrames++;
    return duration == null || duration <= 0
        ? interpolated
        : interpolated.clamp(0, duration);
  }

  // Positive delay means the external ASS cue appears later.
  // Only this cross-source overlay receives a nonzero delay from the player.
  int? _assPosition() {
    final raw = _rawAssPosition();
    return raw == null ? null : (raw - widget.delayMs).clamp(0, 1 << 53).toInt();
  }

  void _onAssFpsChanged() {
    if (!mounted) return;
    _assFps = AssUpdateFrequency.current.value;
    _lastCappedFrameUs = -1;
  }

  void _onFrame(Duration elapsed) {
    if (!_ready || !mounted) return;
    final position = _assPosition();
    if (position == null) return;
    _assTicks++;
    final elapsedUs = elapsed.inMicroseconds;
    if (_assLastTickElapsedUs >= 0) {
      final gap = elapsedUs - _assLastTickElapsedUs;
      if (gap > _assTickMaxGapUs) _assTickMaxGapUs = gap;
    }
    _assLastTickElapsedUs = elapsedUs;
    if (_assLastSamplePosition == position) {
      _assRepeatedPositions++;
    } else {
      _assUniquePositions++;
      _assLastSamplePosition = position;
    }
    if (_rendering) _assBusyTicks++;
    if (_assStatsClock.elapsedMilliseconds >= 5000) {
      final seconds = _assStatsClock.elapsedMilliseconds / 1000.0;
      final avgRenderMs = _assRequests == 0 ? 0.0 : _assRenderTotalUs / _assRequests / 1000.0;
      debugPrint('[ASSRENDER][PERF] ticks/s=${(_assTicks / seconds).toStringAsFixed(1)} '
          'uniquePosition/s=${(_assUniquePositions / seconds).toStringAsFixed(1)} '
          'repeatedPositions=$_assRepeatedPositions busyTicks=$_assBusyTicks '
          'renderRequests/s=${(_assRequests / seconds).toStringAsFixed(1)} '
          'avgRoundtripMs=${avgRenderMs.toStringAsFixed(1)} '
          'maxRoundtripMs=${(_assRenderMaxUs / 1000).toStringAsFixed(1)} '
          'maxTickGapMs=${(_assTickMaxGapUs / 1000).toStringAsFixed(1)} '
          'playerPositionMs=$position clockResyncs=$_clockResyncs '
          'clockSeeks=$_clockSeeks interpolatedFrames=$_clockInterpolatedFrames '
          'freshReports=$_clockFreshReports staleReports=$_clockStaleReports');
      _assStatsClock.reset();
      _assStatsClock.start();
      _assTicks = _assRequests = _assUniquePositions = _assRepeatedPositions = _assBusyTicks = 0;
      _assRenderTotalUs = _assRenderMaxUs = 0;
      _assTickMaxGapUs = 0;
      _clockResyncs = _clockSeeks = _clockInterpolatedFrames = 0;
      _clockStaleReports = _clockFreshReports = 0;
    }
    final active = _cueTimes.any((cue) => cue.$1 <= position && position < cue.$2);
    final nowUs = elapsed.inMicroseconds;
    final minIntervalUs = _assFps == 0 ? 0 : (1000000 / _assFps).ceil();
    final permitted = _lastCappedFrameUs < 0 || nowUs < _lastCappedFrameUs ||
        nowUs - _lastCappedFrameUs >= minIntervalUs;
    if (permitted && (active || _lastPosition < 0 || position < _lastPosition ||
        nowUs - _lastIdlePollUs >= 150000)) {
      _lastCappedFrameUs = nowUs;
      if (!active) _lastIdlePollUs = nowUs;
      _render();
    }
  }

  Future<void> _render() async {
    if (!_ready || _rendering || !mounted) return;
    final generation = _loadedGeneration;
    final position = _assPosition();
    if (position == null || position == _lastPosition) return;
    _rendering = true;
    final renderWatch = Stopwatch()..start();
    _assRequests++;
    try {
      final visible = await _channel.invokeMethod<bool>(
        'renderTexture', {'timeMs': position},
      );
      if (!mounted || !_ready || generation != _generation) return;
      if (visible == false && position ~/ 1000 != _lastDiagnosticSecond &&
          (_lastDiagnosticSecond < 0 || (position ~/ 1000 - _lastDiagnosticSecond).abs() >= 5)) {
        _lastDiagnosticSecond = position ~/ 1000;
        final active = _cueTimes.where((cue) => cue.$1 <= position && position < cue.$2).length;
        debugPrint('[ASSRENDER] Empty frame: player=${position}ms, activeAssCues=$active, parsedCues=${_cueTimes.length}');
      }
      _lastPosition = position;
    } catch (error) {
      debugPrint('[ASSRENDER] Render failed: $error');
      _ready = false;
      _frameTicker.stop();
    } finally {
      renderWatch.stop();
      final elapsedUs = renderWatch.elapsedMicroseconds;
      _assRenderTotalUs += elapsedUs;
      if (elapsedUs > _assRenderMaxUs) _assRenderMaxUs = elapsedUs;
      _rendering = false;
    }
  }

  static int? _parseAssTime(String value) {
    final parts = value.trim().split(':');
    if (parts.length != 3) return null;
    final seconds = parts[2].split('.');
    if (seconds.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final s = int.tryParse(seconds[0]);
    final cs = int.tryParse(seconds[1]);
    if (h == null || m == null || s == null || cs == null) return null;
    return ((h * 3600 + m * 60 + s) * 1000) + cs * 10;
  }

  void _inspectCueTimes(Uint8List bytes) {
    final script = String.fromCharCodes(bytes);
    var inEvents = false;
    var startIndex = 1;
    var endIndex = 2;
    for (final raw in script.split('\n')) {
      final line = raw.trim();
      if (line.startsWith('[')) {
        inEvents = line.toLowerCase() == '[events]';
        continue;
      }
      if (!inEvents) continue;
      if (line.toLowerCase().startsWith('format:')) {
        final fields = line.substring(7).split(',').map((e) => e.trim().toLowerCase()).toList();
        startIndex = fields.indexOf('start');
        endIndex = fields.indexOf('end');
      } else if (line.toLowerCase().startsWith('dialogue:')) {
        final fields = line.substring(9).split(',');
        if (startIndex < 0 || endIndex < 0 || fields.length <= startIndex || fields.length <= endIndex) continue;
        final start = _parseAssTime(fields[startIndex]);
        final end = _parseAssTime(fields[endIndex]);
        if (start != null && end != null && end > start) {
          _cueTimes.add((start, end));

        }
      }
    }
    if (_cueTimes.isNotEmpty) {
      final first = _cueTimes.map((e) => e.$1).reduce((a, b) => a < b ? a : b);
      final last = _cueTimes.map((e) => e.$2).reduce((a, b) => a > b ? a : b);
      debugPrint('[ASSRENDER] ASS timing: cues=${_cueTimes.length}, first=${first}ms, last=${last}ms');
    } else {
      debugPrint('[ASSRENDER] ASS timing: no Dialogue timestamps parsed');
    }
  }

  @override
  void dispose() {
    ++_generation;
    _frameTicker.stop();
    AssUpdateFrequency.current.removeListener(_onAssFpsChanged);
    _frameTicker.dispose();
    widget.controller.removeListener(_onPlayerUpdate);
    _playbackClock.stop();
    if (_ready) {
      _channel.invokeMethod<void>('disposeTexture').catchError((Object _) {});
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textureId = _textureId;
    return IgnorePointer(
      child: textureId == null
          ? const SizedBox.expand()
          : Center(
              child: AspectRatio(
                // The native renderer uses a 1280x720 frame. Match its
                // aspect ratio instead of stretching into pillarbox bars.
                aspectRatio: 1280 / 720,
                child: Texture(textureId: textureId),
              ),
            ),
    );
  }
}
