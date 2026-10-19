import 'package:animestream/core/anime/providers/aniyomiExtensionProvider.dart';
import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/data/animeSpecificPreference.dart';
import 'package:animestream/core/data/types.dart';
import 'package:animestream/ui/models/sources.dart';
import 'package:flutter/material.dart';

class ManualSearchSheet extends StatefulWidget {
  final String searchString;
  final String source;
  final String anilistId;
  const ManualSearchSheet({super.key, required this.searchString, required this.source, required this.anilistId});

  @override
  State<ManualSearchSheet> createState() => _ManualSearchSheetState();
}

class _ManualSearchSheetState extends State<ManualSearchSheet> {
  @override
  void initState() {
    searchBarController.text = widget.searchString;
    search(widget.searchString);
    super.initState();
  }

  TextEditingController searchBarController = TextEditingController();
  FocusNode searchBarFocusNode = FocusNode();
  bool searching = false;
  String? searchFailureType;
  List<Widget> searchResults = [];
  final Set<String> _seenAliases = {};
  String _activeQuery = '';
  int _currentPage = 1;
  int _generation = 0;
  bool _hasMorePages = false;
  bool _loadingMore = false;
  String? _pageFailureType;

  void _appendResults(List<Map<String, String?>> res, String searchTerm) {
      for (final item in res) {
        final key = item['alias'] ?? item['name'] ?? '';
        if (key.isEmpty || !_seenAliases.add(key)) continue;
        searchResults.add(
          GestureDetector(
            onTap: () async {
              if (!AniyomiExtensionProvider.isExtensionId(widget.source)) {
                await saveAnimeSpecificPreference(widget.anilistId,
                    AnimeSpecificPreference(manualSearchQuery: item['name'] ?? searchTerm));
              }
              if (!mounted) return;
              Navigator.of(context).pop(item);
            },
            child: Container(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    height: 140,
                    width: 100,
                    margin: EdgeInsets.only(bottom: 5),
                    clipBehavior: Clip.hardEdge,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
                    child: Image.network(
                      item['imageUrl'] ?? '',
                      fit: BoxFit.cover,
                      height: 140,
                      width: 100,
                    ),
                  ),
                  Text(
                    item['name'] ?? item['alias'] ?? '',
                    style: TextStyle(
                      color: appTheme.textMainColor,
                      fontFamily: 'NotoSans',
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      overflow: TextOverflow.ellipsis,
                    ),
                    maxLines: 2,
                    textAlign: TextAlign.left,
                  )
                ],
              ),
            ),
          ),
        );
      }
  }

  Future<void> search(String searchTerm) async {
    final generation = ++_generation;
    setState(() {
      searchResults.clear();
      _seenAliases.clear();
      searching = true;
      _loadingMore = false;
      _hasMorePages = false;
      _pageFailureType = null;
      _currentPage = 1;
      _activeQuery = searchTerm.trim();
      searchFailureType = null;
    });
    try {
      List<Map<String, String?>> res;
      var active = searchTerm.trim();
      var hasMore = false;
      if (AniyomiExtensionProvider.isExtensionId(widget.source)) {
        var result = await SourceManager.instance.searchExtensionPage(
            widget.source, active, 1);
        res = result.results;
        hasMore = result.hasNextPage;
        // A source may index a season under its base title.
        if (res.isEmpty) {
          final suffix = RegExp(
              r'\s*(?:season|part|cour)\s*\d+\s*' + r'$',
              caseSensitive: false);
          final shorter = active.replaceAll(suffix, '').trim();
          if (shorter.isNotEmpty && shorter != active) {
            active = shorter;
            result = await SourceManager.instance.searchExtensionPage(
                widget.source, active, 1);
            res = result.results;
            hasMore = result.hasNextPage;
          }
        }
      } else {
        res = await SourceManager.instance.searchInSource(
            widget.source, searchTerm);
      }
      if (!mounted || generation != _generation) return;
      setState(() {
        _activeQuery = active;
        _hasMorePages = hasMore;
        _appendResults(res, searchTerm);
      });
    } catch (err) {
      if (!mounted || generation != _generation) return;
      setState(() => searchFailureType = err.runtimeType.toString());
    } finally {
      if (mounted && generation == _generation) {
        setState(() => searching = false);
      }
    }
  }

  Future<void> _loadMore() async {
    if (searching || _loadingMore || !_hasMorePages || _currentPage >= 10) return;
    final generation = _generation;
    final nextPage = _currentPage + 1;
    setState(() {
      _loadingMore = true;
      _pageFailureType = null;
    });
    try {
      final next = await SourceManager.instance.searchExtensionPage(
          widget.source, _activeQuery, nextPage);
      if (!mounted || generation != _generation) return;
      setState(() {
        _appendResults(next.results, _activeQuery);
        _currentPage = nextPage;
        _hasMorePages = next.hasNextPage;
      });
    } catch (error) {
      if (!mounted || generation != _generation) return;
      setState(() => _pageFailureType = error.runtimeType.toString());
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _loadingMore = false);
      }
    }
  }

  @override
  void dispose() {
    ++_generation;
    searchBarController.dispose();
    searchBarFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(right: 15, left: 15, top: 10, bottom: MediaQuery.of(context).padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 45,
            padding: EdgeInsets.only(left: 10, right: 10),
            child: TextField(
              onSubmitted: (val) => search(val),
              controller: searchBarController,
              focusNode: searchBarFocusNode,
              style: TextStyle(color: appTheme.textMainColor, fontFamily: "NotoSans", fontWeight: FontWeight.bold),
              autocorrect: false,
              decoration: InputDecoration(
                contentPadding: EdgeInsets.only(top: 5, bottom: 5, left: 15, right: 20),
                labelText: "search",
                labelStyle: TextStyle(
                    fontFamily: "Poppins",
                    fontWeight: FontWeight.bold,
                    color: searchBarFocusNode.hasFocus ? appTheme.accentColor : appTheme.textMainColor),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(
                    color: appTheme.accentColor,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(
                    color: appTheme.textMainColor,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              // height: 350,
              // margin: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
              padding: EdgeInsets.only(
                top: 10,
              ),
              child: searching
                  ? Center(
                      child: CircularProgressIndicator(
                        color: appTheme.accentColor,
                      ),
                    )
                  : searchResults.isEmpty
                      ? Center(
                          child: Text(
                            searchFailureType == null
                                ? "No Results!"
                                : "Source search failed ($searchFailureType)",
                            style: TextStyle(
                              color: appTheme.textMainColor,
                              fontFamily: "NunitoSans",
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        )
                      : GridView.builder(
                          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 130, mainAxisSpacing: 15, crossAxisSpacing: 15, mainAxisExtent: 190),
                          itemCount: searchResults.length,
                          shrinkWrap: true,
                          padding: EdgeInsets.only(left: 5, right: 5, top: 10),
                          itemBuilder: (context, index) {
                            return MouseRegion(cursor: SystemMouseCursors.click, child: searchResults[index]);
                          },
                        ),
            ),
          ),
          if (AniyomiExtensionProvider.isExtensionId(widget.source) &&
              _hasMorePages && !searching)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: _loadingMore
                  ? const CircularProgressIndicator()
                  : TextButton.icon(
                      onPressed: _loadMore,
                      icon: const Icon(Icons.expand_more),
                      label: const Text('Load more'),
                    ),
            ),
          if (_pageFailureType != null)
            Text('Could not load more ($_pageFailureType)',
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ],
      ),
    );
  }
}
