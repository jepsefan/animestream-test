import 'dart:convert';

class AnimeSpecificPreference {
  final Map? lastWatchDuration;
  final String? manualSearchQuery;
  final String? preferredProvider;
  final String? previouslyUsedServer;
  final String? previouslyUsedServerQuality;

  /// Per-Anime, per-extension manually confirmed source aliases.
  final Map<String, String>? extensionSelections;

  AnimeSpecificPreference({
    this.lastWatchDuration,
    this.manualSearchQuery,
    this.preferredProvider,
    this.previouslyUsedServer,
    this.previouslyUsedServerQuality,
    this.extensionSelections,
  });

  @override
  String toString() =>
      'AnimeSpecificPreference(lastWatchDuration: $lastWatchDuration, manualSearchQuery: $manualSearchQuery, '
      'preferredProvider: $preferredProvider, previouslyUsedServer: $previouslyUsedServer, previouslyUsedServerQuality: $previouslyUsedServerQuality)';

  AnimeSpecificPreference copyWith({
    Map? lastWatchDuration,
    String? manualSearchQuery,
    String? preferredProvider,
    String? previouslyUsedServer,
    String? previouslyUsedServerQuality,
    Map<String, String>? extensionSelections,
  }) {
    return AnimeSpecificPreference(
      lastWatchDuration: lastWatchDuration ?? this.lastWatchDuration,
      manualSearchQuery: manualSearchQuery ?? this.manualSearchQuery,
      preferredProvider: preferredProvider ?? this.preferredProvider,
      previouslyUsedServer: previouslyUsedServer ?? this.previouslyUsedServer,
      previouslyUsedServerQuality:
          previouslyUsedServerQuality ?? this.previouslyUsedServerQuality,
      extensionSelections: extensionSelections ?? this.extensionSelections,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'lastWatchDuration': lastWatchDuration,
      'manualSearchQuery': manualSearchQuery,
      'preferredProvider': preferredProvider,
      'previouslyUsedServer': previouslyUsedServer,
      'previouslyUsedServerQuality': previouslyUsedServerQuality,
      'extensionSelections': extensionSelections,
    };
  }

  factory AnimeSpecificPreference.fromMap(Map<String, dynamic> map) {
    return AnimeSpecificPreference(
      lastWatchDuration: map['lastWatchDuration'] != null
          ? Map.from(map['lastWatchDuration'] as Map<dynamic, dynamic>)
          : null,
      manualSearchQuery: map['manualSearchQuery'] != null
          ? map['manualSearchQuery'] as String
          : null,
      preferredProvider: map['preferredProvider'] != null
          ? map['preferredProvider'] as String
          : null,
      previouslyUsedServer: map['previouslyUsedServer'] != null
          ? map['previouslyUsedServer'] as String
          : null,
      previouslyUsedServerQuality: map['previouslyUsedServerQuality'] != null
          ? map['previouslyUsedServerQuality'] as String
          : null,
      extensionSelections: map['extensionSelections'] is Map
          ? Map<String, String>.from(map['extensionSelections'] as Map)
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory AnimeSpecificPreference.fromJson(String source) =>
      AnimeSpecificPreference.fromMap(
        json.decode(source) as Map<String, dynamic>,
      );
}
