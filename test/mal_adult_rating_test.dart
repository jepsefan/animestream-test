import 'package:flutter_test/flutter_test.dart';
import 'package:animestream/core/metadata/malMetadata.dart';

void main() {
  test('MAL R+ and Rx are adult-rated', () {
    expect(MalAnimeMetadata.isAdultRating('r+', null), isTrue);
    expect(MalAnimeMetadata.isAdultRating('rx', null), isTrue);
    expect(MalAnimeMetadata.isAdultRating('R+', null), isTrue);
  });

  test('MAL plain R and other ratings are not adult by default', () {
    expect(MalAnimeMetadata.isAdultRating('r', null), isFalse);
    expect(MalAnimeMetadata.isAdultRating('pg_13', null), isFalse);
    expect(MalAnimeMetadata.isAdultRating(null, null), isFalse);
  });

  test('MAL recommendation metadata extracts mean score and rating', () {
    final data = MalAnimeMetadata.parseRecommendationMetadata({
      'mean': 7.91, 'rating': 'r+', 'nsfw': 'black',
    });
    expect(data.score, 7.9);
    expect(data.ageRating, 'r+');
    expect(data.isAdult, isTrue);
  });

  test('MAL recommendation metadata handles missing and string scores', () {
    expect(MalAnimeMetadata.parseRecommendationMetadata({'mean': '8.23'}).score, 8.2);
    expect(MalAnimeMetadata.parseRecommendationMetadata({}).score, isNull);
    expect(MalAnimeMetadata.parseRecommendationMetadata({'mean': 'n/a'}).score, isNull);
  });

  test('explicit NSFW flags are retained', () {
    expect(MalAnimeMetadata.isAdultRating('r', true), isTrue);
    expect(MalAnimeMetadata.isAdultRating(null, 'black'), isTrue);
  });
}
