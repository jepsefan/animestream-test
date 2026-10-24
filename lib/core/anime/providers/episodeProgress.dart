import 'package:animestream/core/anime/providers/types.dart';

/// Tracker progress counts completed regular episodes, not source-list slots.
/// A source can include episode 0 and specials anywhere in its list.
class EpisodeProgress {
  const EpisodeProgress._();

  /// Return the next regular episode after [completed], or the last regular
  /// episode if the season is complete. Never auto-start an unnumbered special.
  static int nextIndex(List<EpisodeDetails> episodes, int completed) {
    if (episodes.isEmpty) return 0;
    for (var i = 0; i < episodes.length; i++) {
      if (episodes[i].episodeNumber > completed &&
          episodes[i].episodeNumber > 0) {
        return i;
      }
    }
    for (var i = episodes.length - 1; i >= 0; i--) {
      if (episodes[i].episodeNumber > 0) return i;
    }
    return 0;
  }

  /// Do not mark an episode watched just because playback was opened, or
  /// reduce existing progress. Episode zero has no ordinary tracker progress.
  static int? onOpen(EpisodeDetails episode, int completed) {
    if (episode.episodeNumber <= 0) return null;
    final beforeEpisode = episode.episodeNumber - 1;
    return beforeEpisode > completed ? beforeEpisode : null;
  }

  /// Mark only the actual episode number at the watched threshold.
  static int? onWatched(EpisodeDetails episode, int completed) {
    final number = episode.episodeNumber;
    return number > completed && number > 0 ? number : null;
  }

  /// Stable resume keys for numbered episodes, independent of list order.
  /// Specials get negative keys so they cannot collide with episode 1.
  static int resumeKey(List<EpisodeDetails> episodes, int index) {
    final number = episodes[index].episodeNumber;
    return number > 0 ? number : -(index + 1);
  }

  static String label(EpisodeDetails episode) {
    final sourceLabel = episode.episodeLabel?.trim();
    return sourceLabel != null && sourceLabel.isNotEmpty
        ? sourceLabel
        : 'Episode ${episode.episodeNumber}';
  }

  static bool isWatched(EpisodeDetails episode, int completed) =>
      episode.episodeNumber > 0 && episode.episodeNumber <= completed;
}
