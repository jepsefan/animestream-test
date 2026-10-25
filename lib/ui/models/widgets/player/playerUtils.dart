import 'dart:math';

import 'package:animestream/core/commons/utils.dart';
import 'package:better_player/better_player.dart';
import 'package:flutter/material.dart';

Future<BetterPlayerDataSource> dataSourceConfig(String url, {Map<String, String>? headers = null, bool shareWebViewCookies = false}) async {
  // Determine the stream format once, before configuring the Android player.
  // Apply the original HLS buffer profile to both built-in and [Ext] sources.
  final format = await _getFormat(url, headers);
  final isHls = format == BetterPlayerVideoFormat.hls;

  return BetterPlayerDataSource(
    BetterPlayerDataSourceType.network,
    url,
    videoFormat: format,
    shareWebViewCookies: shareWebViewCookies,
    useAsmsAudioTracks: true,
    useAsmsTracks: true,
    bufferingConfiguration: isHls
        ? const BetterPlayerBufferingConfiguration(
            minBufferMs: 15000,
            maxBufferMs: 120000,
            bufferForPlaybackMs: 2000,
            bufferForPlaybackAfterRebufferMs: 4000,
          )
        : const BetterPlayerBufferingConfiguration(),
    cacheConfiguration: BetterPlayerCacheConfiguration(
      useCache: true,
      maxCacheFileSize: 50 * 1024 * 1024,
      maxCacheSize: 50 * 1024 * 1024,
    ),
    headers: headers,
    placeholder: PlayerLoadingWidget(),
  );
}

/// Identifies formats that can be determined without a network request.
/// Some extension HLS URLs are opaque and have no .m3u8 suffix. In
/// particular, the original hanime.tv source returns /hls/{id}/{token}.
/// Do not apply this route shape to arbitrary websites.
BetterPlayerVideoFormat? inferVideoFormatFromUrl(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return null;
  final path = uri.path.toLowerCase();
  if (path.endsWith('.mpd') || path.endsWith('.dash')) {
    return BetterPlayerVideoFormat.dash;
  }
  if (path.endsWith('.m3u8') || path.endsWith('.m3u')) {
    return BetterPlayerVideoFormat.hls;
  }
  if (const ['.mp4', '.mkv', '.webm', '.mov', '.avi', '.flv', '.ts']
      .any(path.endsWith)) {
    return BetterPlayerVideoFormat.other;
  }

  // The original extension advertises these as HLS playlists despite
  // their extensionless, signed URLs. Resolving via a HEAD request may
  // return HTML/403 from the website's anti-bot layer instead.
  final isHanime = const {'hanime.tv', 'player.hanime.tv'}
      .contains(uri.host.toLowerCase());
  final segments = uri.pathSegments;
  if (uri.scheme == 'https' && isHanime &&
      segments.length >= 3 && segments.first.toLowerCase() == 'hls' &&
      segments[1].isNotEmpty && segments[2].isNotEmpty) {
    return BetterPlayerVideoFormat.hls;
  }
  return null;
}

Future<BetterPlayerVideoFormat> _getFormat(String url, Map<String, String>? headers) async {
  final inferred = inferVideoFormatFromUrl(url);
  if (inferred != null) return inferred;
  String? mime;
  try {
    mime = (await getMediaMimeType(url, headers))?.toLowerCase();
  } catch (_) {
    // Unsupported HEAD requests must not block player initialization.
  }

  // HEAD is not reliable for every protected media endpoint.
  // Preserve the format detected from the URL, if one was available;
  // otherwise let the player select its regular progressive reader.
  if (mime == null || mime.contains("octet-stream")) {
    return BetterPlayerVideoFormat.other;
  } else if (mime.contains("mpegurl")) {
    // MPEG-2 transport stream (video/mp2t) is a media segment, not an HLS
    // playlist; only actual HLS manifests get the tuned buffering profile.
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
