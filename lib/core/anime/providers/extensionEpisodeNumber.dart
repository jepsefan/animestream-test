/// Episode identity as provided by the installed extension. Never invent a
/// series episode number from the result's position; that can play an entirely
/// different episode in long-running series.
class ExtensionEpisodeNumber {
  final int number;
  final String label;
  final double? sortNumber;
  const ExtensionEpisodeNumber(this.number, this.label, this.sortNumber);

  static ExtensionEpisodeNumber parse(Object? raw, String title) {
    final value = raw is num ? raw.toDouble()
        : double.tryParse(raw?.toString().trim() ?? '');
    if (value != null && value.isFinite && value > 0) {
      if (value == value.truncateToDouble() && value <= 2147483647) {
        final n = value.toInt();
        return ExtensionEpisodeNumber(n, 'Episode $n', value);
      }
      // Decimal episodes are specials between regular episodes; don't round
      // 1000.5 to 1001 and thereby misidentify the content.
      final text = value.toString().replaceFirst(RegExp(r'\.0), '');
      return ExtensionEpisodeNumber(0, 'Episode $text', value);
    }
    // Host API uses -1 or NaN for unknown numbers and 0 for special episodes.
    final cleaned = title.trim();
    return ExtensionEpisodeNumber(0,
        cleaned.isEmpty ? 'Special / unnumbered' : cleaned, null);
  }
}
), '');
      return ExtensionEpisodeNumber(0, 'Episode $text', value);
    }
    // Host API uses -1 or NaN for unknown numbers and 0 for special episodes.
    final cleaned = title.trim();
    return ExtensionEpisodeNumber(0,
        cleaned.isEmpty ? 'Special / unnumbered' : cleaned, null);
  }
}
