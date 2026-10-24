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

  test('explicit NSFW flags are retained', () {
    expect(MalAnimeMetadata.isAdultRating('r', true), isTrue);
    expect(MalAnimeMetadata.isAdultRating(null, 'black'), isTrue);
  });
}
