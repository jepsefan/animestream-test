// ignore_for_file: public_member_api_docs, sort_constructors_first
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
    'url': url, 'language': language, 'label': label, 'format': format,
  };

  factory ExternalSubtitleTrack.fromMap(Map<dynamic, dynamic> map) =>
      ExternalSubtitleTrack(
        url: map['url']?.toString() ?? '',
        language: map['language']?.toString() ?? 'Unknown',
        label: map['label']?.toString() ?? 'Unknown',
        format: map['format']?.toString() ?? '',
      );
}

/// External audio supplied by an extension. Metadata is not an HLS track selector.
class ExternalAudioTrack {
  final String url;
  final String language;
  final String label;

  const ExternalAudioTrack({
    required this.url,
    required this.language,
    required this.label,
  });

  Map<String, dynamic> toMap() => {
    'url': url, 'language': language, 'label': label,
  };

  factory ExternalAudioTrack.fromMap(Map<dynamic, dynamic> map) =>
      ExternalAudioTrack(
        url: map['url']?.toString() ?? '',
        language: map['language']?.toString() ?? 'Unknown',
        label: map['label']?.toString() ?? 'Unknown',
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

  /// Additional external audio URLs provided by the source; not selectable yet.
  final List<ExternalAudioTrack> externalAudioTracks;

  /// The server name or identifier
  final String server;

  /// Whether this stream is a backup stream
  final bool backup;

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
    this.externalAudioTracks = const [],
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
      'externalAudioTracks': externalAudioTracks.map((track) => track.toMap()).toList(),
      'server': server,
      'backup': backup,
      'customHeaders': customHeaders,
    };
  }

  factory VideoStream.fromMap(Map<String, dynamic> map) {
    return VideoStream(
      quality: map['quality'] as String,
      url: map['url'] as String,
      subtitle: map['subtitle'] != null ? map['subtitle'] as String : null,
      subtitleFormat: map['subtitleFormat'] != null ? map['subtitleFormat'] : null,
      subtitleTracks: (map['subtitleTracks'] as List?)
          ?.whereType<Map>()
          .map((track) => ExternalSubtitleTrack.fromMap(track))
          .toList() ?? const [],
      externalAudioTracks: (map['externalAudioTracks'] as List?)
          ?.whereType<Map>()
          .map((track) => ExternalAudioTrack.fromMap(track))
          .toList() ?? const [],
      server: map['server'] as String,
      backup: map['backup'] as bool,
      customHeaders:
          map['customHeaders'] != null ? Map<String, String>.from((map['customHeaders'] as Map<String, String>)) : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory VideoStream.fromJson(String source) => VideoStream.fromMap(json.decode(source) as Map<String, dynamic>);
}

class EpisodeDetails {
  /// The episode link or id to be parsed in getStreams function
  final String episodeLink;

  /// Episode number
  final int episodeNumber;

  /// Optional display identity from source, including specials/decimals.
  final String? episodeLabel;

  /// Episode thumbnail url, if available
  final String? thumbnail;

  /// Episode title, if available
  final String? episodeTitle;

  /// Description about the episode. if any
  final String? description;

  /// Dub availability
  final bool? hasDub;

  /// Filler Episode
  final bool? isFiller;

  /// Additional data for processing if required in getStreams function
  final String? metadata;

  EpisodeDetails({
    required this.episodeLink,
    required this.episodeNumber,
    this.episodeLabel,
    this.thumbnail = null,
    this.episodeTitle = null,
    this.hasDub = false,
    this.isFiller = false,
    this.metadata = null,
    this.description = null,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'episodeLink': episodeLink,
      'episodeNumber': episodeNumber,
      'episodeLabel': episodeLabel,
      'thumbnail': thumbnail,
      'episodeTitle': episodeTitle,
      'hasDub': hasDub,
      'isFiller': isFiller,
      'metadata': metadata,
      'description': description,
    };
  }

  factory EpisodeDetails.fromMap(Map<String, dynamic> map) {
    final episodeNumber = map['episodeNumber'];
    final isFiller = map['isFiller'];
    return EpisodeDetails(
      episodeLink: map['episodeLink'] as String,
      episodeNumber: episodeNumber is int ? episodeNumber : int.parse(episodeNumber),
      episodeLabel: map['episodeLabel']?.toString(),
      thumbnail: map['thumbnail'] != null ? map['thumbnail'] as String : null,
      episodeTitle: map['episodeTitle'] != null ? map['episodeTitle'] as String : null,
      hasDub: map['hasDub'] != null
          ? map['hasDub'] is bool
              ? map['hasDub']
              : bool.parse(map['hasDub'])
          : null,
      isFiller: isFiller != null
          ? isFiller is bool
              ? isFiller
              : bool.parse(isFiller)
          : null,
      metadata: map['metadata'] != null ? map['metadata'] as String : null,
      description: map['description'] as String?,
    );
  }

  String toJson() => json.encode(toMap());

  factory EpisodeDetails.fromJson(String source) => EpisodeDetails.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'EpisodeDetails(episodeLink: $episodeLink, episodeNumber: $episodeNumber, thumbnail: $thumbnail, episodeTitle: $episodeTitle, description: $description, hasDub: $hasDub, isFiller: $isFiller, metadata: $metadata)';
  }
}
