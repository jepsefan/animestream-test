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

  Future<void> search(String searchTerm) async {
    if (mounted)
      setState(() {
        searchResults = [];
        searching = true;
        searchFailureType = null;
      });
    try {
      var res = await SourceManager.instance.searchInSource(widget.source, searchTerm);
      // An extension can index a season by the base series title instead.
      // Display those candidates for manual confirmation only.
      if (res.isEmpty && AniyomiExtensionProvider.isExtensionId(widget.source)) {
        final suffix = RegExp(
            r'\s*(?:season|part|cour)\s*\d+\s*' + r'$',
            caseSensitive: false);
        final shortened = searchTerm.replaceAll(suffix, '').trim();
        if (shortened.isNotEmpty && shortened != searchTerm) {
          res = await SourceManager.instance.searchInSource(widget.source, shortened);
        }
      }
      for (final item in res) {
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
    } catch (err) {
      // Do not expose signed URLs or headers from a third-party error.
      searchFailureType = err.runtimeType.toString();
    }
    if (mounted)
      setState(() {
        searching = false;
      });
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
          )
        ],
      ),
    );
  }
}
