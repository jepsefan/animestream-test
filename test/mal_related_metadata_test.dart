import 'package:flutter_test/flutter_test.dart';
import 'package:animestream/core/metadata/malMetadata.dart';

void main() {
  test('MAL related manga preserves adaptation and non-playable type', () {
    final related = MalAnimeMetadata.parseRelations([
      {
        'relation_type': 'adaptation',
        'relation_type_formatted': 'Adaptation',
        'node': {
          'id': 777,
          'title': 'Example light novel',
          'main_picture': {'medium': 'https://example.test/cover.jpg'}
        },
      }
    ], isManga: true);
    expect(related, hasLength(1));
    expect(related.single.providerId, '777');
    expect(related.single.format, 'MANGA');
    expect(related.single.isManga, isTrue);
    expect(related.single.relationType, 'Adaptation');
  });

  test('MAL related anime preserves the source relation type', () {
    final related = MalAnimeMetadata.parseRelations([
      {
        'relation_type': 'sequel',
        'relation_type_formatted': 'Sequel',
        'node': {'id': 888, 'title': 'Next season', 'media_type': 'tv'}
      }
    ]);
    expect(related.single.isManga, isFalse);
    expect(related.single.relationType, 'Sequel');
    expect(related.single.format, 'TV');
  });

  test('missing related entries are safely empty', () {
    expect(MalAnimeMetadata.parseRelations(null), isEmpty);
    expect(MalAnimeMetadata.parseRelations([]), isEmpty);
  });
}
