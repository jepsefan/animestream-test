import 'package:flutter_test/flutter_test.dart';
import 'package:animestream/core/anime/providers/extensionEpisodeNumber.dart';

void main() {
  group('extension episode identity', () {
    test('one piece 1000 is never mapped to an index', () {
      final parsed = ExtensionEpisodeNumber.parse(1000.0, 'Episode 1000');
      expect(parsed.number, 1000);
      expect(parsed.label, 'Episode 1000');
    });
    test('decimal episode never rounds into the next episode', () {
      final parsed = ExtensionEpisodeNumber.parse(1000.5, 'Episode 1000.5');
      expect(parsed.number, 0);
      expect(parsed.label, 'Episode 1000.5');
    });
    test('explicit episode zero has its own label', () {
      final parsed = ExtensionEpisodeNumber.parse(0, 'Special episode');
      expect(parsed.number, 0);
      expect(parsed.label, 'Episode 0');
      expect(parsed.sortNumber, 0);
    });
    test('string zero is also explicit episode zero', () {
      final parsed = ExtensionEpisodeNumber.parse('0', '');
      expect(parsed.label, 'Episode 0');
    });
    test('unnumbered specials do not receive invented ordinals', () {
      final parsed = ExtensionEpisodeNumber.parse(-1, 'Special: Recap');
      expect(parsed.number, 0);
      expect(parsed.label, 'Special: Recap');
    });
    test('missing metadata retains its title', () {
      final parsed = ExtensionEpisodeNumber.parse(null, 'OVA 1');
      expect(parsed.number, 0);
      expect(parsed.label, 'OVA 1');
    });
  });
}
