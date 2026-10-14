import 'package:animestream/core/anime/providers/aniyomiRepository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AniyomiRepositoryExtension', () {
    test('parses package, version, languages, and source labels', () {
      final extension = AniyomiRepositoryExtension.fromMap({
        'name': 'Aniyomi: Example',
        'pkg': 'eu.kanade.tachiyomi.animeextension.en.example',
        'apk': 'aniyomi-en.example-v1.2.apk',
        'version': '1.2',
        'nsfw': 0,
        'sources': [
          {'name': 'Example', 'lang': 'en', 'baseUrl': 'https://example.test'},
          {'name': 'Example', 'lang': 'ja', 'baseUrl': 'https://example.test'},
        ],
      });

      expect(extension.packageName,
          'eu.kanade.tachiyomi.animeextension.en.example');
      expect(extension.languageLabel, 'en, ja');
      expect(extension.sourceLabel, 'Example');
    });

    test('rejects APK paths outside the repository APK directory', () {
      expect(
        () => AniyomiRepositoryExtension.fromMap({
          'pkg': 'eu.example.extension',
          'apk': '../other.apk',
        }),
        throwsFormatException,
      );
    });
  });

  test('accepts an AniYomi add-repo link and unwraps its HTTPS JSON URL', () {
    expect(
      AniyomiRepository.normalizeIndexUrl(
          'aniyomi://add-repo?url=https%3A%2F%2Fexample.org%2Frepo%2Findex.min.json'),
      'https://example.org/repo/index.min.json',
    );
    expect(
      () => AniyomiRepository.normalizeIndexUrl('http://example.org/index.json'),
      throwsFormatException,
    );
  });

  test('builds APK URLs under the repository apk folder', () {
    final repository = AniyomiRepository(
        indexUrl: 'https://example.org/repo/index.min.json');
    final extension = AniyomiRepositoryExtension.fromMap({
      'pkg': 'eu.example.extension',
      'apk': 'example-v1.apk',
      'version': '1',
    });

    expect(repository.apkUri(extension).toString(),
        'https://example.org/repo/apk/example-v1.apk');
  });
}
