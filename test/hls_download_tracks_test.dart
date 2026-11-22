import 'package:animestream/core/commons/hlsParser/hlsParser.dart';
import 'package:animestream/core/commons/streams/streamResolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('matches each HLS variant to its own downloadable audio group', () {
    final manifest = HlsParser.parseMaster(
      '''
#EXTM3U
#EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID="dub",LANGUAGE="en",NAME="English, Stereo",URI="../audio/en.m3u8"
#EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID="original",NAME="Original",URI="ja/audio.m3u8"
#EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID="muxed",NAME="Already in the video"
#EXT-X-STREAM-INF:BANDWIDTH=2000000,RESOLUTION=1280x720,AUDIO="dub"
# A comment before the variant URL
video/720.m3u8?variant=fork
#EXT-X-STREAM-INF:BANDWIDTH=3000000,AUDIO="original"
video/default.m3u8
''',
      Uri.parse('https://example.com/player/manifest.m3u8'),
    );

    expect(manifest.qualityStreams.map((stream) => stream.quality),
        ['720p', 'default']);
    expect(manifest.audioStreams, hasLength(2));
    final audio = StreamResolver.audioFor(
            manifest.qualityStreams.first, manifest.audioStreams)
        .single;
    expect(audio.name, 'English, Stereo');
    expect(audio.url, 'https://example.com/audio/en.m3u8');
    expect(manifest.qualityStreams.first.url,
        'https://example.com/player/video/720.m3u8?variant=fork');
    expect(
        StreamResolver.audioFor(
                manifest.qualityStreams.last, manifest.audioStreams)
            .single
            .language,
        'und');
  });

  test('keeps a media playlist available as one video', () {
    const url = 'https://example.com/media.m3u8?token=example';
    final result = HlsParser.parseMaster(
        '#EXTM3U\n#EXTINF:6.0,\npart1.ts', Uri.parse(url));
    expect(result.qualityStreams.single.url, url);
    expect(result.audioStreams, isEmpty);
  });
}
