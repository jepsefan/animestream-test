import 'package:animestream/core/anime/providers/models.dart';
import 'package:animestream/core/commons/streams/streamResolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reads a stream stored before dub and external subtitle tracks', () {
    final stream = VideoStream.fromMap({
      'quality': '1080p',
      'url': 'https://example.com/video.m3u8',
      'server': 'Test',
      'backup': false,
      'subtitle': 'https://example.com/subtitles.vtt',
      'subtitleFormat': 'vtt',
    });

    expect(stream.dub, isFalse);
    expect(stream.subtitleTracks, isEmpty);
    expect(stream.subtitleFormat, 'vtt');
  });

  test('round-trips dub, extension subtitle tracks and request headers', () {
    final stream = VideoStream(
      quality: '1080p',
      url: 'https://example.com/video.mpd?token=private',
      server: 'Test',
      backup: false,
      dub: true,
      customHeaders: {'Authorization': 'private'},
      subtitleTracks: const [
        ExternalSubtitleTrack(
          url: 'https://example.com/subtitles.ass',
          language: 'English',
          label: 'Signs and songs',
          format: 'ass',
        ),
      ],
    );

    expect(VideoStream.fromJson(stream.toJson()).toMap(), stream.toMap());
    expect(stream.toString(), isNot(contains('private')));
    expect(StreamResolver.isExpandable(stream), isTrue);
  });
}
