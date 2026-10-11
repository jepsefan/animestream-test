import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:animestream/ui/models/playerControllers/videoController.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  });

  final VideoController controller;
  final String subtitleSource;
  final Map<String, String> headers;
  final bool isOffline;

  @override
  State<ExternalAssOverlay> createState() => _ExternalAssOverlayState();
}

class _ExternalAssOverlayState extends State<ExternalAssOverlay> {
  static const _channel = MethodChannel('animestream.app/assrender');
  Timer? _timer;
  int? _textureId;
  bool _ready = false;
  bool _rendering = false;
  int _generation = 0;
  int _lastPosition = -1;
  int _loadedGeneration = -1;
  final List<(int, int)> _cueTimes = [];
  int _lastDiagnosticSecond = -1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant ExternalAssOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.subtitleSource != widget.subtitleSource ||
        oldWidget.isOffline != widget.isOffline ||
        oldWidget.headers.toString() != widget.headers.toString()) {
      _load();
    }
  }

  Future<void> _load() async {
    final generation = ++_generation;
    _timer?.cancel();
    _ready = false;
    _textureId = null;
    _lastPosition = -1;
    _cueTimes.clear();
    _lastDiagnosticSecond = -1;
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
      debugPrint('[ASSRENDER] Loading ${bytes.length} bytes from ${widget.subtitleSource}');
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
      _timer = Timer.periodic(const Duration(milliseconds: 16), (_) => _render());
      _render();
    } catch (error) {
      debugPrint('[ASSRENDER] Native overlay unavailable: $error');
    }
  }

  Future<void> _render() async {
    if (!_ready || _rendering || !mounted) return;
    final generation = _loadedGeneration;
    final position = widget.controller.position;
    if (position == null || position == _lastPosition) return;
    _rendering = true;
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
      _timer?.cancel();
    } finally {
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
        if (start != null && end != null && end > start) _cueTimes.add((start, end));
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
    _timer?.cancel();
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
          : SizedBox.expand(child: Texture(textureId: textureId)),
    );
  }
}
