/// Preserve episode identities supplied by installed extensions.
///
/// Never replace an unknown episode number with a list position: doing so can
/// open a different episode, especially in long-running series.
class ExtensionEpisodeNumber {
  final int number;
  final String label;
  final double? sortNumber;

  const ExtensionEpisodeNumber(this.number, this.label, this.sortNumber);

  static ExtensionEpisodeNumber parse(Object? raw, String title) {
    final value = raw is num
        ? raw.toDouble()
        : double.tryParse(raw?.toString().trim() ?? '');

    // Zero is a legitimate episode number. Do not treat it like the host's
    // unknown-number sentinel (-1/NaN/null).
    if (value == 0) {
      return const ExtensionEpisodeNumber(0, 'Episode 0', 0);
    }

    if (value != null && value.isFinite && value > 0) {
      if (value == value.truncateToDouble() && value <= 2147483647) {
        final number = value.toInt();
        return ExtensionEpisodeNumber(number, 'Episode $number', value);
      }

      // Decimal episodes (e.g. 1000.5) must never round to episode 1001.
      return ExtensionEpisodeNumber(0, 'Episode $value', value);
    }

    // For missing or unknown numbers, keep the source's original title.
    final sourceTitle = title.trim();
    return ExtensionEpisodeNumber(
      0,
      sourceTitle.isEmpty ? 'Special / unnumbered' : sourceTitle,
      null,
    );
  }
}
