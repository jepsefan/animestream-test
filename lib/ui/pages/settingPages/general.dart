import 'dart:io';

import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/data/preferences.dart';
import 'package:animestream/core/data/settings.dart';
import 'package:animestream/core/data/types.dart';
import 'package:animestream/core/database/database.dart';
import 'package:animestream/ui/models/sources.dart';
import 'package:animestream/core/anime/providers/providerDetails.dart';
import 'package:animestream/ui/models/widgets/clickableItem.dart';
import 'package:animestream/ui/models/widgets/toggleItem.dart';
import 'package:animestream/ui/pages/settingPages/cache.dart';
import 'package:animestream/ui/pages/settingPages/common.dart';
import 'package:animestream/ui/pages/settingPages/plugin.dart';
import 'package:animestream/ui/pages/settingPages/providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GeneralSetting extends StatefulWidget {
  const GeneralSetting({super.key});

  @override
  State<GeneralSetting> createState() => _GeneralSettingState();
}

class _GeneralSettingState extends State<GeneralSetting> {
  @override
  initState() {
    readSettings().then((val) => setState(() {
          loaded = true;
        }));
    super.initState();
  }

  Future<void> readSettings() async {
    final settings = await Settings().getSettings();
    setState(() {
      showErrorsButtonState = settings.showErrors!;
      receivePreReleases = settings.receivePreReleases!;
      fasterDownloads = settings.fasterDownloads!;
      useQueuedDownloads = settings.useQueuedDownloads!;
      enableLogging = settings.enableLogging!;
    });
  }

  Future<void> writeSettings(SettingsModal settings) async {
    await Settings().writeSettings(settings);
    setState(() {
      readSettings();
    });
  }

  bool loaded = false;
  bool showErrorsButtonState = false;
  bool receivePreReleases = false;
  bool fasterDownloads = false;
  bool useQueuedDownloads = false;
  bool enableDiscordPresence = false;
  bool useDesktopNativeDiscordPresence = false;
  bool enableLogging = false;

  List<ProviderDetails> get sources => SourceManager.instance.sources;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appTheme.backgroundColor,
      body: loaded
          ? SingleChildScrollView(
              child: Padding(
                padding: pagePadding(context, bottom: true),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    settingPagesTitleHeader(context, "General"),
                    ToggleItem(
                      label: "Show errors",
                      value: showErrorsButtonState,
                      onTapFunction: () {
                        setState(() {
                          showErrorsButtonState = !showErrorsButtonState;
                        });
                        writeSettings(SettingsModal(showErrors: showErrorsButtonState));
                      },
                    ),
                    ToggleItem(
                      label: "Receive beta updates",
                      value: receivePreReleases,
                      onTapFunction: () {
                        setState(() {
                          receivePreReleases = !receivePreReleases;
                        });
                        writeSettings(SettingsModal(receivePreReleases: receivePreReleases));
                      },
                      description: "*maybe unstable",
                    ),
                    ToggleItem(
                      label: "Quick play",
                      description: "Automatically play the episodes using the last server you used",
                      value: userPreferences?.autoSelectPreviouslyUsedServer ?? false,
                      onTapFunction: () async {
                        await UserPreferences.saveUserPreferences(UserPreferencesModal(
                          autoSelectPreviouslyUsedServer: !(userPreferences?.autoSelectPreviouslyUsedServer ?? false),
                        ));
                        setState(() {});
                      },
                    ),
                    if (Platform.isWindows || Platform.isLinux)
                      ToggleItem(
                        label: "Enable Discord Rich Presence",
                        value: currentUserSettings?.enableDiscordRichPresence ?? false,
                        onTapFunction: () async {
                          await writeSettings(SettingsModal(
                              enableDiscordRichPresence: !(currentUserSettings!.enableDiscordRichPresence ?? false)));
                          setState(() {});
                        },
                      ),
                    if (kDebugMode)
                      ClickableItem(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            showDragHandle: true,
                            isScrollControlled: true,
                            builder: (context) => _databaseSheet(context),
                          );
                        },
                        label: "Default database",
                        description: (currentUserSettings?.database?.name ?? Databases.anilist.name),
                        suffixIcon: Icon(Icons.arrow_drop_down),
                      ),
                    ClickableItem(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          showDragHandle: true,
                          isScrollControlled: true,
                          builder: (context) => _providerSheet(context),
                        );
                      },
                      label: "Default provider",
                      description:
                          (currentUserSettings?.preferredProvider ??
                              (sources.isEmpty ? 'No provider' : sources.first.identifier)).replaceAll('_', ' '),
                      suffixIcon: Icon(Icons.arrow_drop_down),
                    ),
                    ClickableItem(
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(builder: (context) => PluginPage()));
                      },
                      label: "Manage Providers",
                      description: "Add or remove providers",
                      suffixIcon: Icon(Icons.navigate_next_rounded),
                    ),
                    ClickableItem(
                      label: "Built-in providers",
                      description: "Enable streaming sources and metadata fallbacks",
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const BuiltInProvidersPage()),
                      ).then((_) { if (mounted) setState(() {}); }),
                      suffixIcon: Icon(Icons.navigate_next_rounded),
                    ),
                    ClickableItem(
                      label: "Cache Manager",
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => CacheSetting())),
                      description: "Manage network & API cache",
                      suffixIcon: Icon(Icons.navigate_next_rounded),
                    ),
                    // Got clowned for this decision
                    // ClickableItem(
                    //   label: "Downloader",
                    //   onTap: () =>
                    //       Navigator.of(context).push(MaterialPageRoute(builder: (context) => DownloaderSettings())),
                    //   description: "Configure your downloads",
                    //   suffixIcon: Icon(Icons.navigate_next_rounded),
                    // ),
                    ToggleItem(
                      onTapFunction: () {
                        setState(() {
                          enableLogging = !enableLogging;
                        });
                        writeSettings(SettingsModal(enableLogging: enableLogging));
                      },
                      label: "Enable Logging",
                      description: "Helps with debugging issues",
                      value: enableLogging,
                    )
                  ],
                ),
              ),
            )
          : Container(),
    );
  }

  StatefulBuilder _databaseSheet(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setcState) => Container(
        padding: const EdgeInsets.only(
          top: 10,
          left: 20,
          right: 20,
        ),
        margin: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Text(
                "Select Database",
                style: textStyle().copyWith(fontSize: 23),
                textAlign: TextAlign.left,
              ),
            ),
            ListView.builder(
                shrinkWrap: true,
                itemCount: Databases.values.length,
                itemBuilder: (context, index) {
                  final activeDatabase = currentUserSettings?.database?.name ?? Databases.anilist.name;
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    clipBehavior: Clip.hardEdge,
                    decoration: BoxDecoration(
                      color: Databases.values[index].name == activeDatabase
                          ? appTheme.accentColor
                          : appTheme.backgroundSubColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () async {
                          await writeSettings(SettingsModal(database: Databases.values[index]));
                          setState(() {});
                          setcState(() {});
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                          child: Text(
                            Databases.values[index].name,
                            style: textStyle().copyWith(
                              color: Databases.values[index].name == activeDatabase
                                  ? appTheme.onAccent
                                  : appTheme.textMainColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
          ],
        ),
      ),
    );
  }

  Widget _providerSheet(BuildContext context) {
    return _ScrollableProviderSheet(
      sources: List<ProviderDetails>.of(sources),
      selectedProvider: currentUserSettings?.preferredProvider ??
          (sources.isEmpty ? '' : sources.first.identifier),
      onSelected: (identifier) async {
        await writeSettings(SettingsModal(preferredProvider: identifier));
      },
    );
  }
}

/// Keeps the original provider row appearance while constraining the sheet to
/// the screen and allowing DPAD focus to follow a fully built, scrolling list.
/// A Column (rather than a lazy builder) ensures offscreen rows have FocusNodes
/// so Android TV can navigate to them before they become visible.
class _ScrollableProviderSheet extends StatefulWidget {
  final List<ProviderDetails> sources;
  final String selectedProvider;
  final Future<void> Function(String identifier) onSelected;

  const _ScrollableProviderSheet({
    required this.sources,
    required this.selectedProvider,
    required this.onSelected,
  });

  @override
  State<_ScrollableProviderSheet> createState() => _ScrollableProviderSheetState();
}

class _ScrollableProviderSheetState extends State<_ScrollableProviderSheet> {
  late final List<FocusNode> _focusNodes;
  late final List<GlobalKey> _rowKeys;
  late String _selectedProvider;
  late int _focusedIndex;

  @override
  void initState() {
    super.initState();
    _selectedProvider = widget.selectedProvider;
    _focusedIndex = widget.sources.indexWhere(
      (source) => source.identifier == _selectedProvider,
    );
    if (_focusedIndex < 0) _focusedIndex = 0;
    _focusNodes = List.generate(widget.sources.length, (_) => FocusNode());
    _rowKeys = List.generate(widget.sources.length, (_) => GlobalKey());
  }

  @override
  void dispose() {
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _focusRow(int index) {
    if (index < 0 || index >= _focusNodes.length) return;
    _focusNodes[index].requestFocus();
  }

  void _onRowFocus(int index, bool hasFocus) {
    if (!hasFocus || !mounted) return;
    final wasFocused = _focusedIndex;
    setState(() => _focusedIndex = index);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_focusNodes[index].hasFocus) return;
      final rowContext = _rowKeys[index].currentContext;
      if (rowContext == null) return;
      Scrollable.ensureVisible(
        rowContext,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        alignmentPolicy: index < wasFocused
            ? ScrollPositionAlignmentPolicy.keepVisibleAtStart
            : ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // Constrain only the sheet's viewport; keep the original row styling.
    final maxHeight = MediaQuery.sizeOf(context).height * 0.9;
    final contentHeight = 80.0 + widget.sources.length * 75.0;
    final sheetHeight = contentHeight < maxHeight ? contentHeight : maxHeight;
    return SizedBox(
      height: sheetHeight,
      child: Container(
        padding: const EdgeInsets.only(top: 10, left: 20, right: 20),
        margin: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Text(
                'Select Provider',
                style: textStyle().copyWith(fontSize: 23),
                textAlign: TextAlign.left,
              ),
            ),
            Expanded(
              child: Focus(
                canRequestFocus: false,
                skipTraversal: true,
                onKeyEvent: (node, event) {
                  if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
                    return KeyEventResult.ignored;
                  }
                  if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                    _focusRow(_focusedIndex + 1);
                    return KeyEventResult.handled;
                  }
                  if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                    _focusRow(_focusedIndex - 1);
                    return KeyEventResult.handled;
                  }
                  return KeyEventResult.ignored;
                },
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      for (var index = 0; index < widget.sources.length; index++)
                        _providerRow(index),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _providerRow(int index) {
    final source = widget.sources[index];
    final isSelected = source.identifier == _selectedProvider;
    final isFocused = _focusedIndex == index && _focusNodes[index].hasFocus;
    return Container(
      key: _rowKeys[index],
      margin: const EdgeInsets.symmetric(vertical: 5),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: isSelected ? appTheme.accentColor : appTheme.backgroundSubColor,
        borderRadius: BorderRadius.circular(20),
        // Focus ring is distinct from the green selected-provider fill.
        border: isFocused
            ? Border.all(
                color: isSelected ? appTheme.onAccent : appTheme.accentColor,
                width: 2.5,
              )
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          focusNode: _focusNodes[index],
          autofocus: index == _focusedIndex,
          onFocusChange: (focused) => _onRowFocus(index, focused),
          borderRadius: BorderRadius.circular(20),
          onTap: () async {
            try {
              await widget.onSelected(source.identifier);
              if (mounted) setState(() => _selectedProvider = source.identifier);
            } catch (_) {
              // Leave the previous green selection intact if saving fails.
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                source.name,
                style: textStyle().copyWith(
                  color: isSelected ? appTheme.onAccent : appTheme.textMainColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
