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
  Uint8List? _frame;
  bool _ready = false;
  bool _rendering = false;
  int _generation = 0;
  int _lastPosition = -1;
  int _loadedGeneration = -1;

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
    _frame = null;
    _lastPosition = -1;
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
      await _channel.invokeMethod<void>('load', {
        'script': bytes,
        'width': 1280,
        'height': 720,
      });
      if (!mounted || generation != _generation) return;
      _loadedGeneration = generation;
      _ready = true;
      _timer = Timer.periodic(const Duration(milliseconds: 100), (_) => _render());
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
      final frame = await _channel.invokeMethod<Uint8List>(
        'render', {'timeMs': position},
      );
      if (!mounted || !_ready || generation != _generation) return;
      _lastPosition = position;
      setState(() => _frame = frame);
    } catch (error) {
      debugPrint('[ASSRENDER] Render failed: $error');
      _ready = false;
      _timer?.cancel();
    } finally {
      _rendering = false;
    }
  }

  @override
  void dispose() {
    ++_generation;
    _timer?.cancel();
    if (_ready) {
      _channel.invokeMethod<void>('dispose').catchError((Object _) {});
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final frame = _frame;
    return IgnorePointer(
      child: frame == null
          ? const SizedBox.expand()
          : SizedBox.expand(
              child: Image.memory(
                frame,
                fit: BoxFit.contain,
                gaplessPlayback: true,
                filterQuality: FilterQuality.low,
              ),
            ),
    );
  }
}
