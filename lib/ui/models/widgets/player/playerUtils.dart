import 'dart:math';

import 'package:animestream/core/commons/utils.dart';
import 'package:better_player/better_player.dart';
import 'package:flutter/material.dart';

Future<BetterPlayerDataSource> dataSourceConfig(String url, {Map<String, String>? headers = null}) async {
  final format = await _getFormat(url, headers);
  final isHlsOrDash = format == BetterPlayerVideoFormat.hls || format == BetterPlayerVideoFormat.dash;

  return BetterPlayerDataSource(
    BetterPlayerDataSourceType.network,
    url,
    videoFormat: format,
    videoExtension: _getVideoExtension(url),
    useAsmsAudioTracks: true,
    useAsmsTracks: true,
    bufferingConfiguration: const BetterPlayerBufferingConfiguration(
      minBufferMs: 15000,
      maxBufferMs: 120000,
      bufferForPlaybackMs: 2000,
      bufferForPlaybackAfterRebufferMs: 4000,
    ),
    cacheConfiguration: isHlsOrDash
        ? const BetterPlayerCacheConfiguration(
            useCache: true,
            maxCacheFileSize: 50 * 1024 * 1024,
            maxCacheSize: 50 * 1024 * 1024,
          )
        : null,
    headers: headers,
    placeholder: PlayerLoadingWidget(),
  );
}

String? _getVideoExtension(String url) {
  final lower = Uri.tryParse(url)?.path.toLowerCase() ?? url.toLowerCase();
  if (lower.endsWith('.mkv')) return 'mkv';
  if (lower.endsWith('.mp4')) return 'mp4';
  if (lower.endsWith('.webm')) return 'webm';
  if (lower.endsWith('.mov')) return 'mov';
  return null;
}

Future<BetterPlayerVideoFormat> _getFormat(String url, Map<String, String>? headers) async {
  // Select manifest formats by path before sending HEAD: some CDN-backed DASH
  // endpoints reject HEAD although ExoPlayer can fetch the manifest via GET.
  final path = Uri.tryParse(url)?.path.toLowerCase() ?? '';
  if (path.endsWith('.mpd') || path.endsWith('.dash')) {
    return BetterPlayerVideoFormat.dash;
  }
  if (path.endsWith('.m3u8') || path.endsWith('.m3u')) {
    return BetterPlayerVideoFormat.hls;
  }
  if (_getVideoExtension(path) != null) return BetterPlayerVideoFormat.other;
  String? mime;
  try {
    mime = (await getMediaMimeType(url, headers))?.toLowerCase();
  } catch (_) {
    // Unsupported HEAD requests must not block player initialization.
  }

  // lets assume stuff if something goes wrong
  if (mime == null || mime.contains("octet-stream")) {
    final urlPath = Uri.parse(url).path.toLowerCase();

    //guessing game
    if (urlPath.endsWith(".m3u8") || urlPath.endsWith(".m3u")) return BetterPlayerVideoFormat.hls;
    if (urlPath.endsWith(".mpd") || urlPath.endsWith(".dash")) return BetterPlayerVideoFormat.dash;
    return BetterPlayerVideoFormat.other;

  } else if (mime.contains("mpegurl") || mime.contains("mp2t")) {
    return BetterPlayerVideoFormat.hls;

  } else if (mime.contains("dash")) {
    return BetterPlayerVideoFormat.dash;
    
  } else {
    return BetterPlayerVideoFormat.other;
  }
}

class PlayerLoadingWidget extends StatelessWidget {
  const PlayerLoadingWidget({
    super.key,
  });

  // Why not have some fun :)
  final messages = const [
    "Loading Your Anime...",
    "Tweaking the pixels...",
    "Setting up the fun...",
    "Tried Oreshura? Loading anyway...",
    "Just a moment, Senpai...",
    ":)",
    "Cooking up the playback...",
    "Hold on! Will Ya?",
    "Aligning the frames...",
    "anime...stream...ing...",
  ];

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              height: 200,
              width: 200,
              child: Image.asset(
                "lib/assets/icons/logo_foreground.png",
                opacity: AlwaysStoppedAnimation(0.6),
              )),
          Text(
            messages[Random().nextInt(messages.length)],
            style: TextStyle(color: Colors.grey, fontFamily: "Rubik", fontWeight: FontWeight.bold),
          )
        ],
      ),
    );
  }
}

/**Format seconds to hour:min:sec format */
String getFormattedTime(int timeInSeconds) {
  String formatTime(int val) {
    return val.toString().padLeft(2, '0');
  }

  int hours = timeInSeconds ~/ 3600;
  int minutes = (timeInSeconds % 3600) ~/ 60;
  int seconds = timeInSeconds % 60;

  String formattedHours = hours == 0 ? '' : formatTime(hours);
  String formattedMins = formatTime(minutes);
  String formattedSeconds = formatTime(seconds);

  return "${formattedHours.length > 0 ? "$formattedHours:" : ''}$formattedMins:$formattedSeconds";
}
