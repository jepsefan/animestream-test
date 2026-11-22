import 'package:animestream/core/commons/streams/streamRef.dart';

class QualityStream {
  String quality;
  String url;
  String resolution;
  String? audioGroup;
  int? bandwidth;

  final StreamRef? _ref;

  /// Where this quality's segments come from. Defaults to treating [url] as a HLS media playlist.
  StreamRef get ref => _ref ?? HlsRef(url);

  QualityStream({
    required this.quality,
    required this.url,
    required this.resolution,
    this.audioGroup,
    this.bandwidth,
    StreamRef? ref,
  }) : _ref = ref;

  factory QualityStream.paceholder() {
    return QualityStream(quality: "unset", url: "unknown", resolution: "0x0");
  }

  Map<String, dynamic> toMap() {
    return {
      'quality': quality,
      'url': url,
      'resolution': resolution,
      'audioGroup': audioGroup,
      'bandwidth': bandwidth,
    };
  }

  @override
  String toString() {
    return 'QualityStream(quality: $quality, resolution: $resolution, audioGroup: $audioGroup, bandwidth: $bandwidth)';
  }
}
