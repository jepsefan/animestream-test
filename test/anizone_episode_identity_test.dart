import 'package:flutter_test/flutter_test.dart';
import 'package:animestream/core/anime/providers/aniZoneEpisodeIdentity.dart';

void main() {
  const series = 'https://anizone.to/anime/5vkncg7n';
  test('Guardian Fitz is episode zero and plays before episode one', () {
    final id = AniZoneEpisodeIdentity.fromSource(
      animeUrl: series,
      episodeUrl: '$series/s1',
      title: 'Guardian Fitz',
      type: 'special',
      regularIndex: 12,
      specialIndex: 1,
    );
    expect(id.number, 0);
    expect(id.label, 'Episode 0');
    expect(id.moveBeforeRegularEpisodes, isTrue);
  });

  test('ordinary episodes keep source numbering despite trailing special', () {
    final id = AniZoneEpisodeIdentity.fromSource(
      animeUrl: series,
      episodeUrl: '$series/12',
      title: 'I Want to Tell You',
      type: 'Regular Episode',
      regularIndex: 12,
      specialIndex: 1,
    );
    expect(id.number, 12);
    expect(id.moveBeforeRegularEpisodes, isFalse);
  });

  test('other shows specials do not become ep0 or move to the start', () {
    final id = AniZoneEpisodeIdentity.fromSource(
      animeUrl: 'https://anizone.to/anime/unrelated',
      episodeUrl: 'https://anizone.to/anime/unrelated/s1',
      title: 'OVA',
      type: 'Special',
      regularIndex: 12,
      specialIndex: 1,
    );
    expect(id.label, 'Special 1');
    expect(id.moveBeforeRegularEpisodes, isFalse);
  });
}
