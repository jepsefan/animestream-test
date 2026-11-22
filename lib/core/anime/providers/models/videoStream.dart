import 'dart:convert';

/// An external subtitle track exposed by an Aniyomi video source.
class ExternalSubtitleTrack {
  final String url;
  final String language;
  final String label;
  final String format;

  const ExternalSubtitleTrack({
    required this.url,
    required this.language,
    required this.label,
    required this.format,
  });

  Map<String, dynamic> toMap() => {
    'url': url,
    'language': language,
    'label': label,
    'format': format,
  };

  factory ExternalSubtitleTrack.fromMap(Map<dynamic, dynamic> map) =>
      ExternalSubtitleTrack(
        url: map['url']?.toString() ?? '',
        language: map['language']?.toString() ?? 'Unknown',
        label: map['label']?.toString() ?? 'Unknown',
        format: map['format']?.toString() ?? '',
      );
}

class VideoStream {
  /// The quality of the video stream.
  ///
  /// The format for quality is recommended to be "\<quality_string> [\<size>]".
  ///
  /// for example: "1080p [260 MB]" or "multi-quality"
  ///
  /// the size part is optional and can be omitted if unknown
  final String quality;

  /// The URL of the video. Can be a direct link to the video file or a stream playlist like m3u8 or dash
  final String url;

  /// The URL of the subtitle file, if available
  final String? subtitle;

  /// The format of the subtitle file, if available
  final String? subtitleFormat;

  /// All available external subtitle tracks. Ordinary sources can continue
  /// using subtitle/subtitleFormat without providing this list.
  final List<ExternalSubtitleTrack> subtitleTracks;

  /// The server name or identifier
  final String server;

  /// Whether this stream is a backup stream
  final bool backup;

  final bool dub;

  /// The custom headers to be used when making requests to the video URL, optional unless required to access the stream
  final Map<String, String>? customHeaders;

  VideoStream({
    required this.quality,
    required this.url,
    required this.server,
    required this.backup,
    this.subtitleFormat = null,
    this.subtitle = null,
    this.subtitleTracks = const [],
    this.dub = false,
    this.customHeaders = null,
  });

  @override
  String toString() {
    // Stream URLs can embed signed tokens and custom headers may carry auth.
    // Never include them in logs or debug-print interpolation.
    return 'VideoStream(quality: $quality, server: $server, backup: $backup, '
        'hasSubtitle: ${subtitle != null}, hasCustomHeaders: ${customHeaders?.isNotEmpty ?? false})';
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'quality': quality,
      'url': url,
      'subtitle': subtitle,
      'subtitleFormat': subtitleFormat,
      'subtitleTracks': subtitleTracks.map((track) => track.toMap()).toList(),
      'server': server,
      'backup': backup,
      'dub': dub,
      'customHeaders': customHeaders,
    };
  }

  factory VideoStream.fromMap(Map<String, dynamic> map) {
    return VideoStream(
      quality: map['quality'] as String,
      url: map['url'] as String,
      subtitle: map['subtitle'] != null ? map['subtitle'] as String : null,
      subtitleFormat: map['subtitleFormat'] != null
          ? map['subtitleFormat']
          : null,
      subtitleTracks:
          (map['subtitleTracks'] as List?)
              ?.whereType<Map>()
              .map((track) => ExternalSubtitleTrack.fromMap(track))
              .toList() ??
          const [],
      server: map['server'] as String,
      backup: map['backup'] as bool,
      dub: map['dub'] as bool? ?? false,
      customHeaders: map['customHeaders'] != null
          ? Map<String, String>.from(
              map['customHeaders'] as Map,
            )
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory VideoStream.fromJson(String source) =>
      VideoStream.fromMap(json.decode(source) as Map<String, dynamic>);
}
