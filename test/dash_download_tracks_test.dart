import 'package:animestream/core/commons/dashParser/dashParser.dart';
import 'package:animestream/core/commons/streams/streamRef.dart';
import 'package:animestream/core/commons/streams/streamResolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('resolves distinct DASH video and audio representations', () {
    const url = 'https://example.com/manifest.mpd?token=example';
    final manifest = DashParser.parse(r'''
<MPD type="static" mediaPresentationDuration="PT4S">
  <Period>
    <AdaptationSet mimeType="video/mp4">
      <Representation id="video" bandwidth="2000000" width="1280" height="720">
        <SegmentTemplate initialization="video/init.mp4" media="video/part-$Number$.m4s" duration="2"/>
      </Representation>
    </AdaptationSet>
    <AdaptationSet mimeType="audio/mp4" lang="ja">
      <Representation id="audio" bandwidth="128000">
        <SegmentTemplate initialization="audio/init.mp4" media="audio/part-$Number$.m4s" duration="2"/>
      </Representation>
    </AdaptationSet>
  </Period>
</MPD>
''', url);
    final video = manifest.qualityStreams.single;
    final audio = StreamResolver.audioFor(video, manifest.audioStreams).single;
    expect(video.quality, '720p');
    expect(video.ref, isA<DashRef>());
    expect(audio.language, 'ja');
    expect(audio.ref, isA<DashRef>());
    expect(audio.url, url);
  });
}
