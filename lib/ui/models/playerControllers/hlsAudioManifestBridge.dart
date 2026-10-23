import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:animestream/core/anime/providers/types.dart';

/// Supplies ExoPlayer with a small local HLS *master* manifest when an
/// extension returns a video-only HLS variant and a separate AUDIO rendition.
/// The remote media stays on the source hosts; this never proxies media bytes.
/// A single session is bound to 127.0.0.1 and released with the player.
class HlsAudioManifestBridge {
  HttpServer? _server;
  final Map<String, String> _manifests = {};

  static bool _validUrl(String value) {
    if (value.contains('\n') || value.contains('\r') || value.contains('"')) {
      return false;
    }
    final uri = Uri.tryParse(value);
    return uri != null && uri.hasAuthority &&
        (uri.scheme == 'https' || uri.scheme == 'http');
  }

  static String _safeLabel(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^a-zA-Z0-9 _.-]'), '').trim();
    return cleaned.isEmpty ? 'Audio' : cleaned.substring(0, min(60, cleaned.length));
  }

  /// Re:ANIME's FlixCloud proxy deliberately uses
  /// http://127.0.0.1:<port>/proxy?url=<encoded manifest>&w_payload=<token>
  /// with no .m3u8 suffix. The source's own PlaylistUtils already identified
  /// the stream as HLS and provided the external AUDIO renditions. Restrict
  /// this fallback to that precise loopback proxy shape so ordinary files,
  /// including direct MKV links, continue through normal playback.
  static bool _isKnownHlsProxy(Uri uri) {
    final isLoopback = uri.host == '127.0.0.1' ||
        uri.host == 'localhost' || uri.host == '::1';
    return isLoopback && uri.path == '/proxy' &&
        uri.queryParameters.containsKey('url') &&
        uri.queryParameters.containsKey('w_payload');
  }

  Future<String> prepare(VideoStream stream, {String? selectedAudioUrl}) async {
    final video = stream.url;
    final uri = Uri.tryParse(video);
    final isHls = uri != null &&
        (uri.path.toLowerCase().endsWith('.m3u8') ||
            _isKnownHlsProxy(uri));
    if (!Platform.isAndroid || !_validUrl(video) ||
        !isHls || stream.externalAudioTracks.isEmpty) {
      return video;
    }
    final tracks = stream.externalAudioTracks
        .where((track) => _validUrl(track.url))
        .take(12).toList();
    if (tracks.isEmpty) return video;
    // Re:ANIME labels the HOSTER as [Sub] or [Dub]. The same HLS video
    // master may contain multiple audio renditions. Prefer the language that
    // matches the chosen hoster rather than always picking its first audio.
    final server = stream.server.toLowerCase();
    final preferred = server.contains('[dub]')
        ? RegExp(r'^(en|eng|english)([-_ ]|$)', caseSensitive: false)
        : server.contains('[sub]')
            ? RegExp(r'^(ja|jpn|jp|japanese)([-_ ]|$)', caseSensitive: false)
            : null;
    final ordered = [...tracks];
    if (preferred != null) {
      ordered.sort((a, b) {
        final aMatch = preferred.hasMatch(a.language.trim()) ||
            preferred.hasMatch(a.label.trim());
        final bMatch = preferred.hasMatch(b.language.trim()) ||
            preferred.hasMatch(b.label.trim());
        return aMatch == bMatch ? 0 : (aMatch ? -1 : 1);
      });
    }
    if (selectedAudioUrl != null) {
      ordered.sort((a, b) => a.url == selectedAudioUrl ? -1
          : b.url == selectedAudioUrl ? 1 : 0);
    }
    try {
      _server ??= await HttpServer.bind(InternetAddress.loopbackIPv4, 0,
          shared: false);
      if (_manifests.isEmpty) {
        _serve(_server!);
      }
      final token = List<int>.generate(16, (_) => Random.secure().nextInt(256))
          .map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
      final buffer = StringBuffer('#EXTM3U\n#EXT-X-VERSION:3\n');
      for (var i = 0; i < ordered.length; i++) {
        final lang = _safeLabel(ordered[i].language);
        final label = _safeLabel(ordered[i].label.isEmpty ? lang : ordered[i].label);
        buffer.writeln('#EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID="ext-audio",'
            'NAME="${label}_${i + 1}",LANGUAGE="$lang",'
            'DEFAULT=${i == 0 ? 'YES' : 'NO'},AUTOSELECT=YES,'
            'URI="${ordered[i].url}"');
      }
      // A variant playlist carries video segments, while the AUDIO group
      // supplies the separate sound segments as native HLS renditions.
      buffer.writeln('#EXT-X-STREAM-INF:BANDWIDTH=4000000,AUDIO="ext-audio"');
      buffer.writeln(video);
      _manifests
        ..clear()
        ..[token] = buffer.toString();
      return 'http://127.0.0.1:${_server!.port}/hls/$token.m3u8';
    } catch (_) {
      // Never prevent normal playback just because the optional bridge failed.
      return video;
    }
  }

  void _serve(HttpServer server) {
    unawaited(() async {
      try {
        await for (final request in server) {
          final name = request.uri.pathSegments.isEmpty ? '' : request.uri.pathSegments.last;
          final key = name.endsWith('.m3u8')
              ? name.substring(0, name.length - 5) : '';
          final body = request.uri.pathSegments.length == 2 &&
                  request.uri.pathSegments.first == 'hls'
              ? _manifests[key] : null;
          if (request.connectionInfo?.remoteAddress.isLoopback != true ||
              body == null) {
            request.response.statusCode = HttpStatus.notFound;
          } else {
            request.response.headers.contentType =
                ContentType('application', 'vnd.apple.mpegurl', charset: 'utf-8');
            request.response.write(body);
          }
          await request.response.close();
        }
      } catch (_) {
        // Closing the player will close its loopback HTTP server.
      }
    }());
  }

  Future<void> close() async {
    _manifests.clear();
    final server = _server;
    _server = null;
    await server?.close(force: true);
  }
}
