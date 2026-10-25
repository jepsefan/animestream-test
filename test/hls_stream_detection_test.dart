import 'package:flutter_test/flutter_test.dart';
import 'package:better_player/better_player.dart';
import 'package:animestream/ui/models/widgets/player/playerUtils.dart';

void main() {
  group('extension stream format detection', () {
    test('recognizes signed extensionless hanime HLS URLs', () {
      expect(inferVideoFormatFromUrl(
          'https://hanime.tv/hls/example-id/opaque-token'),
          BetterPlayerVideoFormat.hls);
      expect(inferVideoFormatFromUrl(
          'https://player.hanime.tv/hls/123/opaque-token?expires=1'),
          BetterPlayerVideoFormat.hls);
    });

    test('does not assume unrelated extensionless endpoints are HLS', () {
      expect(inferVideoFormatFromUrl(
          'https://another.example/hls/123/opaque-token'), isNull);
    });

    test('recognizes explicit HLS and DASH URL paths with query strings', () {
      expect(inferVideoFormatFromUrl(
          'https://cdn.example/video/master.m3u8?token=abc'),
          BetterPlayerVideoFormat.hls);
      expect(inferVideoFormatFromUrl(
          'https://cdn.example/video/manifest.mpd?token=abc'),
          BetterPlayerVideoFormat.dash);
    });

    test('does not classify direct video files as HLS', () {
      expect(inferVideoFormatFromUrl('https://cdn.example/video.mp4'),
          BetterPlayerVideoFormat.other);
      expect(inferVideoFormatFromUrl('https://cdn.example/video.mkv'),
          BetterPlayerVideoFormat.other);
    });
  });
}
