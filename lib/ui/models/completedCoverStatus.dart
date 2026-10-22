import 'dart:async';

import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/commons/enums.dart';
import 'package:animestream/core/database/anilist/queries.dart';
import 'package:animestream/core/database/anilist/types.dart';
import 'package:flutter/foundation.dart';

/// Completed refers to the signed-in user's AniList watch status, NOT the
/// series' publication/release status. One request loads all IDs, not one
/// request per cover. An unknown status never shades a poster.
class CompletedCoverStatus extends ChangeNotifier {
  CompletedCoverStatus._();
  static final CompletedCoverStatus instance = CompletedCoverStatus._();

  static const _cacheDuration = Duration(minutes: 10);
  String? _userName;
  Set<int> _completed = <int>{};
  DateTime? _lastChecked;
  Future<void>? _pending;
  int _generation = 0;

  bool contains(int animeId) => animeId > 0 && _completed.contains(animeId);

  void clear() {
    _generation++;
    _userName = null;
    _lastChecked = null;
    _completed = <int>{};
    _pending = null;
    notifyListeners();
  }

  void _switchUser(String user) {
    if (_userName == user) return;
    _generation++;
    _userName = user;
    _completed = <int>{};
    _lastChecked = null;
    _pending = null;
    notifyListeners();
  }

  /// Reuse the all-list response when the user visits My Lists.
  void seedFromLists(String user, List<UserAnimeList> lists) {
    _switchUser(user);
    _completed = lists
        .where((list) => list.status.toUpperCase() == 'COMPLETED')
        .expand((list) => list.list)
        .map((entry) => entry.id)
        .where((id) => id > 0)
        .toSet();
    _lastChecked = DateTime.now();
    notifyListeners();
  }

  /// Refresh after switching accounts or when cards first become visible.
  /// Failures preserve the last known IDs; request errors must not prevent
  /// displaying covers or opening a series.
  Future<void> ensureLoaded({bool force = false}) async {
    final user = storedUserData?.name;
    if (user == null || user.isEmpty) {
      if (_userName != null) clear();
      return;
    }
    _switchUser(user);
    if (_pending != null) return _pending!;
    final last = _lastChecked;
    if (!force && last != null &&
        DateTime.now().difference(last) < _cacheDuration) return;

    final generation = _generation;
    final request = _fetchCompleted(user, generation);
    _pending = request;
    try {
      await request;
    } finally {
      if (identical(_pending, request)) _pending = null;
    }
  }

  Future<void> _fetchCompleted(String user, int generation) async {
    // Rate limit failures as well: do not repeatedly query for every cover.
    _lastChecked = DateTime.now();
    try {
      final lists = await AnilistQueries()
          .getUserAnimeList(user, status: MediaStatus.COMPLETED);
      if (generation != _generation || _userName != user) return;
      _completed = lists
          .where((list) => list.status.toUpperCase() == 'COMPLETED')
          .expand((list) => list.list)
          .map((entry) => entry.id)
          .where((id) => id > 0)
          .toSet();
      notifyListeners();
    } catch (_) {
      // Keep existing shading if AniList is temporarily unavailable.
    }
  }

  /// Apply a successful list mutation immediately without refetching.
  void setCompleted(int id, bool completed) {
    final user = storedUserData?.name;
    if (user == null || user.isEmpty || id <= 0) return;
    _switchUser(user);
    if (completed) {
      _completed.add(id);
    } else {
      _completed.remove(id);
    }
    notifyListeners();
  }
}
