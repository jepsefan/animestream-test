import 'package:flutter_test/flutter_test.dart';
import 'package:animestream/core/anime/providers/episodeProgress.dart';
import 'package:animestream/core/anime/providers/types.dart';

EpisodeDetails ep(int number, String name) => EpisodeDetails(
  episodeLink: 'https://example.invalid/$name',
  episodeNumber: number,
  episodeLabel: name,
);

void main() {
  final episodes = [ep(0, 'Episode 0'), ep(1, 'Episode 1'), ep(2, 'Episode 2')];

  test('unwatched series starts episode 1 rather than episode 0', () {
    expect(EpisodeProgress.nextIndex(episodes, 0), 1);
  });
  test('watched episode 1 continues at episode 2', () {
    expect(EpisodeProgress.nextIndex(episodes, 1), 2);
  });
  test('playing episode 0 never changes trackers', () {
    expect(EpisodeProgress.onOpen(episodes[0], 0), isNull);
    expect(EpisodeProgress.onWatched(episodes[0], 0), isNull);
  });
  test('episode 1 reports 1 and not list position 2', () {
    expect(EpisodeProgress.onWatched(episodes[1], 0), 1);
  });
  test('replaying old episode never downgrades watched count', () {
    expect(EpisodeProgress.onWatched(episodes[1], 10), isNull);
    expect(EpisodeProgress.onOpen(episodes[1], 10), isNull);
  });
  test('resume keys are not shifted by episode zero', () {
    expect(EpisodeProgress.resumeKey(episodes, 0), -1);
    expect(EpisodeProgress.resumeKey(episodes, 1), 1);
    expect(EpisodeProgress.resumeKey(episodes, 2), 2);
  });
  test('episode 0 is not marked watched by regular tracker progress', () {
    expect(EpisodeProgress.isWatched(episodes[0], 12), isFalse);
    expect(EpisodeProgress.isWatched(episodes[1], 12), isTrue);
  });
}
