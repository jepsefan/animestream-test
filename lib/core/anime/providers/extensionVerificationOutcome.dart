/// A completed catalogue search is not the same as a successful title match.
/// In particular, an empty result does not prove that WebView verification
/// failed: the selected source may simply not contain the requested title.
enum ExtensionVerificationOutcome {
  matchFound,
  noTitleResults,
  unrelatedTitleResults,
  blockedOrFailed,
}

/// Interpret the already-sanitized result from the selected native extension.
/// No URLs, cookies or authentication details are needed for this decision.
ExtensionVerificationOutcome extensionVerificationOutcome(
    Map<String, dynamic> response) {
  final status = response['status']?.toString();
  if (status != 'search_completed' &&
      status != 'search_completed_unverified') {
    return ExtensionVerificationOutcome.blockedOrFailed;
  }

  final count = (response['resultCount'] as num?)?.toInt() ??
      ((response['results'] as List?)?.length ?? 0);
  if (count <= 0) {
    return ExtensionVerificationOutcome.noTitleResults;
  }

  if (response['resultRelevance'] == 'unverified_unrelated_catalogue') {
    return ExtensionVerificationOutcome.unrelatedTitleResults;
  }

  return ExtensionVerificationOutcome.matchFound;
}
