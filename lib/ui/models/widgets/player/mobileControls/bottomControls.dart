import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/data/assUpdateFrequency.dart';
import 'package:animestream/core/data/assMotionSmoothing.dart';
import 'package:animestream/ui/models/bottomSheets/customControlsSheet.dart';
import 'package:animestream/ui/models/providers/playerDataProvider.dart';
import 'package:animestream/ui/models/providers/playerProvider.dart';
import 'package:animestream/ui/pages/settingPages/common.dart';
import 'package:animestream/ui/pages/settingPages/subtitle.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class BottomControls extends StatefulWidget {
  final FocusNode? firstFocusNode;

  const BottomControls({
    super.key,
    this.firstFocusNode,
  });

  @override
  State<BottomControls> createState() => _BottomControlsState();
}

class _BottomControlsState extends State<BottomControls> {
  final FocusNode _qualityFallbackFocusNode =
      FocusNode(debugLabel: 'player_quality');
  final FocusNode _serverFocusNode =
      FocusNode(debugLabel: 'player_servers');
  final FocusNode _episodeFocusNode =
      FocusNode(debugLabel: 'player_episodes');
  final FocusNode _speedFocusNode =
      FocusNode(debugLabel: 'player_speed');
  final FocusNode _subtitleFocusNode =
      FocusNode(debugLabel: 'player_subtitles');
  final FocusNode _assFpsFocusNode = FocusNode(debugLabel: 'player_ass_fps');
  final FocusNode _audioFocusNode =
      FocusNode(debugLabel: 'player_audio');
  final FocusNode _pipFocusNode =
      FocusNode(debugLabel: 'player_pip');
  final FocusNode _viewModeFocusNode =
      FocusNode(debugLabel: 'player_view_mode');

  FocusNode get _qualityFocusNode =>
      widget.firstFocusNode ?? _qualityFallbackFocusNode;

  List<FocusNode> get _horizontalFocusOrder => [
        _qualityFocusNode,
        _serverFocusNode,
        _episodeFocusNode,
        _speedFocusNode,
        _subtitleFocusNode,
        _assFpsFocusNode,
        _audioFocusNode,
        _pipFocusNode,
        _viewModeFocusNode,
      ];

  KeyEventResult _handleHorizontalDpad(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final isLeft = event.logicalKey == LogicalKeyboardKey.arrowLeft;
    final isRight = event.logicalKey == LogicalKeyboardKey.arrowRight;
    if (!isLeft && !isRight) return KeyEventResult.ignored;

    final order = _horizontalFocusOrder;
    final index = order.indexWhere((focusNode) => focusNode.hasFocus);
    if (index == -1) return KeyEventResult.ignored;

    final nextIndex = isRight ? index + 1 : index - 1;
    if (nextIndex < 0 || nextIndex >= order.length) {
      return KeyEventResult.handled;
    }

    order[nextIndex].requestFocus();
    return KeyEventResult.handled;
  }

  @override
  void dispose() {
    _qualityFallbackFocusNode.dispose();
    _serverFocusNode.dispose();
    _episodeFocusNode.dispose();
    _speedFocusNode.dispose();
    _subtitleFocusNode.dispose();
    _assFpsFocusNode.dispose();
    _audioFocusNode.dispose();
    _pipFocusNode.dispose();
    _viewModeFocusNode.dispose();
    super.dispose();
  }

  void showSheet(BuildContext context, Widget child) => showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: appTheme.modalSheetBackgroundColor,
      context: context,
      builder: (BuildContext context) {
        return child;
      });

  void _showSubtitleTracks(
      BuildContext context,
      PlayerDataProvider dataProvider,
      PlayerProvider playerProvider) {
    // Format labels are populated progressively by inspecting the first bytes
    // of each source-provided subtitle, without exposing signed URLs.
    dataProvider.inspectRemainingSubtitleTracks();
    // The modal is a sibling route: Provider.of inside it may fail.
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: appTheme.modalSheetBackgroundColor,
      builder: (sheetContext) {
        final height = MediaQuery.sizeOf(sheetContext).height * 0.75;
        return SafeArea(
          child: SizedBox(
            height: height > 430 ? 430 : height,
            child: AnimatedBuilder(
              animation: Listenable.merge([dataProvider, playerProvider]),
              builder: (context, _) {
                final tracks = dataProvider.availableSubtitleTracks;
                final selected = dataProvider.selectedSubtitleTrack;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                      child: Text(
                        'Subtitle tracks (${tracks.length})',
                        style: TextStyle(fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: appTheme.textMainColor),
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        children: [
                          ListTile(
                            leading: Icon(
                              !playerProvider.state.showSubs
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_unchecked,
                              color: appTheme.textMainColor,
                            ),
                            title: Text('Off',
                                style: TextStyle(color: appTheme.textMainColor)),
                            onTap: () {
                              playerProvider.toggleSubs(action: false);
                              Navigator.of(sheetContext).pop();
                            },
                          ),
                          if (dataProvider.hasCrossSourceAss ||
                              dataProvider.crossSourceError != null ||
                              dataProvider.crossSourceLoading)
                            ListTile(
                              title: const Text('External ASS'),
                              subtitle: Text(dataProvider.crossSourceLoading
                                  ? 'Searching external subtitle source...'
                                  : (dataProvider.crossSourceError ?? 'Active')),
                            ),
                          for (final slot in ['primary', 'secondary'])
                            ListTile(
                              leading: const Icon(Icons.closed_caption_outlined),
                              title: Text('Load ${slot == 'primary' ? 'Primary' : 'Secondary'} ASS'),
                              onTap: () async {
                                await dataProvider.loadCrossSourceAss(selectedSlot: slot);
                                if (!sheetContext.mounted) return;
                                if (dataProvider.hasCrossSourceAss) {
                                  playerProvider.toggleSubs(action: true);
                                  Navigator.of(sheetContext).pop();
                                } else {
                                  ScaffoldMessenger.of(sheetContext).showSnackBar(
                                    SnackBar(content: Text(dataProvider.crossSourceError ??
                                        'No matching external ASS found')),
                                  );
                                }
                              },
                            ),
                          for (final track in tracks)
                            ListTile(
                              leading: Icon(
                                playerProvider.state.showSubs &&
                                        selected?.url == track.url
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_unchecked,
                                color: appTheme.textMainColor,
                              ),
                              title: Text(track.label.isNotEmpty
                                  ? track.label : track.language,
                                  style: TextStyle(color: appTheme.textMainColor)),
                              subtitle: Text(
                                '${track.language} • ${dataProvider.subtitleFormatLabel(track)}',
                                style: TextStyle(color:
                                    appTheme.textMainColor.withOpacity(0.7)),
                              ),
                              onTap: () async {
                                // Probe subtitle content before switching the
                                // renderer; source filenames may be opaque.
                                await dataProvider.selectSubtitleTrack(track);
                                if (!sheetContext.mounted) return;
                                if (dataProvider.subtitleFormatFor(track).isNotEmpty) {
                                  playerProvider.toggleSubs(action: true);
                                } else {
                                  playerProvider.toggleSubs(action: false);
                                  ScaffoldMessenger.of(sheetContext).showSnackBar(
                                    const SnackBar(content: Text(
                                      'Subtitle format is not recognized. '
                                      'This track cannot be rendered yet.',
                                    )),
                                  );
                                }
                                Navigator.of(sheetContext).pop();
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dataProvider = context.read<PlayerDataProvider>();
    final playerProvider = context.read<PlayerProvider>();
    // final a = dataProvider.state.currentAudioTrack;
    // playerProvider.controller.setAudioTrack(a.url, a.language, a.name);

    return dataProvider.state.controlsLocked
        ? Container()
        : Focus(
            onKeyEvent: _handleHorizontalDpad,
            child: Container(
              height: 40,
              child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      focusNode: _qualityFocusNode,
                      onPressed: () {
                        showModalBottomSheet(
                          isScrollControlled: true,
                          context: context,
                          backgroundColor: appTheme.modalSheetBackgroundColor,
                          showDragHandle: false,
                          barrierColor: Color.fromARGB(17, 255, 255, 255),
                          builder: (BuildContext context) {
                            return Container(
                              width: 400,
                              padding: EdgeInsets.all(20),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: Text(
                                      "Choose Quality",
                                      style:
                                          TextStyle(color: appTheme.textMainColor, fontFamily: "Rubik", fontSize: 20),
                                    ),
                                  ),
                                  ListView.builder(
                                    itemCount: dataProvider.state.qualities.length,
                                    shrinkWrap: true,
                                    physics: NeverScrollableScrollPhysics(),
                                    itemBuilder: (BuildContext context, index) {
                                      return Container(
                                        padding: EdgeInsets.only(left: 25, right: 25),
                                        child: ElevatedButton(
                                          onPressed: () async {
                                            // final src = dataProvider.state.qualities[index].url;
                                            dataProvider.updateCurrentQuality(dataProvider.state.qualities[index]);
                                            playerProvider.setQuality(dataProvider.state.qualities[index]);
                                            // selectedQuality = dataProvider.state.qualities[index]['quality'] ?? '720';
                                            // dataProvider.updateCurrentQuality(dataProvider.state.qualities[index]);
                                            // playerProvider.playVideo(src,
                                            //     currentStream: dataProvider.state.currentStream,
                                            //     preserveProgress: true);
                                            Navigator.pop(context);
                                          },
                                          style: ElevatedButton.styleFrom(
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                              // side: BorderSide(color: Colors.white)
                                            ),
                                            backgroundColor: dataProvider.state.qualities[index].url ==
                                                    dataProvider.state.currentQuality.url
                                                ? appTheme.accentColor
                                                : appTheme.backgroundSubColor,
                                          ),
                                          child: Text(
                                            "${dataProvider.state.qualities[index].quality}",
                                            style: TextStyle(
                                              color: dataProvider.state.qualities[index].url ==
                                                      dataProvider.state.currentQuality.url
                                                  ? appTheme.onAccent
                                                  : appTheme.accentColor,
                                              fontFamily: "Poppins",
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                      tooltip: "qualities",
                      icon: Icon(
                        Icons.high_quality_rounded,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      focusNode: _serverFocusNode,
                      onPressed: () {
                        showSheet(
                          context,
                          CustomControlsBottomSheet(
                            index: dataProvider.state.currentEpIndex,
                            dataProvider: dataProvider,
                            playerProvider: playerProvider,
                          ),
                        );
                      },
                      tooltip: "servers",
                      icon: Icon(
                        Icons.source_rounded,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      focusNode: _episodeFocusNode,
                      onPressed: () {
                        showModalBottomSheet(
                          isScrollControlled: true,
                          backgroundColor: appTheme.modalSheetBackgroundColor,
                          context: context,
                          builder: (context) => Container(
                            padding: EdgeInsets.only(left: 20, right: 20, top: 15),
                            height: MediaQuery.of(context).size.height - 80,
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 20),
                                  child: Text(
                                    "Select Episode",
                                    style: textStyle().copyWith(fontSize: 23),
                                  ),
                                ),
                                Container(
                                  height: MediaQuery.of(context).size.height - 150,
                                  child: GridView.builder(
                                    itemCount: dataProvider.epLinks.length,
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2, childAspectRatio: 4),
                                    shrinkWrap: true,
                                    padding: EdgeInsets.only(left: 10, right: 10),
                                    itemBuilder: (context, index) {
                                      return GestureDetector(
                                        onTap: () {
                                          Navigator.pop(context);
                                          if (index == dataProvider.state.currentEpIndex) return;
                                          sheet2(index, context, playerProvider, dataProvider);
                                        },
                                        child: Container(
                                          margin: EdgeInsets.all(5),
                                          height: 50,
                                          decoration: BoxDecoration(
                                              color: index == dataProvider.state.currentEpIndex
                                                  ? appTheme.accentColor
                                                  : appTheme.backgroundSubColor,
                                              borderRadius: BorderRadius.circular(12)),
                                          alignment: Alignment.center,
                                          child: Text(
                                            "Episode ${index + 1}",
                                            style: TextStyle(
                                              color: index == dataProvider.state.currentEpIndex
                                                  ? appTheme.backgroundColor
                                                  : appTheme.textMainColor,
                                              fontFamily: "Rubik",
                                              fontSize: 20,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      tooltip: "Episode list",
                      icon: Icon(
                        Icons.view_list_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),

                //right side
                Row(
                  children: [
                    IconButton(
                      focusNode: _speedFocusNode,
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return playBackSpeedDialog(context, playerProvider, dataProvider);
                          },
                        );
                      },
                      tooltip: "Playback speed",
                      icon: Icon(
                        Icons.speed_rounded,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      focusNode: _subtitleFocusNode,
                      onPressed: () {
                        if (dataProvider.availableSubtitleTracks.length > 1) {
                          _showSubtitleTracks(context, dataProvider, playerProvider);
                        } else {
                          playerProvider.toggleSubs();
                        }
                      },
                      onLongPress: () {
                        Navigator.of(context)
                            .push(MaterialPageRoute(
                                builder: (ctx) => SubtitleSettingPage(
                                      fromWatchPage: true,
                                    )))
                            .then((v) {
                          dataProvider.initSubsettings();
                        });
                      },
                      tooltip: "Subtitle tracks",
                      icon: Icon(
                        !playerProvider.state.showSubs ? Icons.subtitles_outlined : Icons.subtitles_rounded,
                        color: Colors.white,
                      ),
                    ),
                    ValueListenableBuilder<int>(
                      valueListenable: AssUpdateFrequency.current,
                      builder: (context, selectedFps, _) => PopupMenuButton<int>(
                        tooltip: "ASS update frequency",
                        icon: const Icon(Icons.tune, color: Colors.white),
                        initialValue: selectedFps,
                        onOpened: () { AssUpdateFrequency.ensureLoaded(); },
                        onSelected: (fps) async {
                          await AssUpdateFrequency.save(fps);
                        },
                        itemBuilder: (context) => [
                          CheckedPopupMenuItem<int>(
                            value: 0,
                            checked: selectedFps == 0,
                            child: Container(
                              color: selectedFps == 0 ? Colors.green.withOpacity(0.18) : null,
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Text("ASS Auto (display vsync)",
                                style: TextStyle(fontWeight: selectedFps == 0 ? FontWeight.bold : FontWeight.normal)),
                            ),
                          ),
                          ...List.generate(30, (index) {
                            final fps = index + 1;
                            final selected = selectedFps == fps;
                            return CheckedPopupMenuItem<int>(
                              value: fps,
                              checked: selected,
                              child: Container(
                                color: selected ? Colors.green.withOpacity(0.18) : null,
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Text("ASS $fps FPS",
                                  style: TextStyle(fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    ValueListenableBuilder<AssSmoothingMode>(
                      valueListenable: AssMotionSmoothing.current,
                      builder: (context, mode, _) => PopupMenuButton<AssSmoothingMode>(
                        tooltip: 'ASS Motion Smoothing',
                        icon: const Icon(Icons.motion_photos_on_outlined, color: Colors.white),
                        initialValue: mode,
                        onOpened: () { AssMotionSmoothing.ensureLoaded(); },
                        onSelected: AssMotionSmoothing.save,
                        itemBuilder: (context) => [
                          CheckedPopupMenuItem<AssSmoothingMode>(
                            value: AssSmoothingMode.off,
                            checked: mode == AssSmoothingMode.off,
                            child: const Text('Motion Smoothing: Av'),
                          ),
                          CheckedPopupMenuItem<AssSmoothingMode>(
                            value: AssSmoothingMode.automaticPositionInterpolation,
                            checked: mode == AssSmoothingMode.automaticPositionInterpolation,
                            child: const Text('Automatisk positionsinterpolering'),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      focusNode: _audioFocusNode,
                      onPressed: () {
                        showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            builder: (context) {
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Padding(
                                  padding: const EdgeInsets.only(bottom: 20, top: 20),
                                  child: Text(
                                    "Audio Track",
                                    style: textStyle().copyWith(fontSize: 23),
                                  ),
                                ),
                                  ListView.builder(
                                    itemCount: dataProvider.state.audioTracks.length,
                                    shrinkWrap: true,
                                    itemBuilder: (BuildContext context, index) {
                                      return Container(
                                        padding: EdgeInsets.only(left: 25, right: 25),
                                        child: ElevatedButton(
                                          onPressed: () async {
                                            // final src = dataProvider.state.qualities[index].url;
                                            dataProvider.updateCurrentAudioTrack(dataProvider.state.audioTracks[index]);
                                            playerProvider.controller.setAudioTrack(dataProvider.state.currentAudioTrack);
                                            // selectedQuality = dataProvider.state.qualities[index]['quality'] ?? '720';
                                            // dataProvider.updateCurrentQuality(dataProvider.state.qualities[index]);
                                            // playerProvider.playVideo(src,
                                            //     currentStream: dataProvider.state.currentStream,
                                            //     preserveProgress: true);
                                            Navigator.pop(context);
                                          },
                                          style: ElevatedButton.styleFrom(
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                              // side: BorderSide(color: Colors.white)
                                            ),
                                            backgroundColor: dataProvider.state.audioTracks[index].url ==
                                                    dataProvider.state.currentAudioTrack.url
                                                ? appTheme.accentColor
                                                : appTheme.backgroundSubColor,
                                          ),
                                          child: Text(
                                            "${dataProvider.state.audioTracks[index].name} (${dataProvider.state.audioTracks[index].language})",
                                            style: TextStyle(
                                              color: dataProvider.state.audioTracks[index].url ==
                                                      dataProvider.state.currentAudioTrack.url
                                                  ? appTheme.onAccent
                                                  : appTheme.accentColor,
                                              fontFamily: "Poppins",
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              );
                            });
                      },
                      icon: Icon(Icons.audiotrack_rounded),
                      tooltip: "Audio Tracks",
                      color: Colors.white,
                    ),
                    IconButton(
                      focusNode: _pipFocusNode,
                      onPressed: () async {
                        await playerProvider.setPip(!playerProvider.state.pip);
                      },
                      icon: Icon(Icons.picture_in_picture_alt_rounded),
                      tooltip: "Picture in Picture",
                      color: Colors.white,
                    ),
                    IconButton(
                      focusNode: _viewModeFocusNode,
                      onPressed: () {
                        playerProvider.cycleViewMode();
                      },
                      icon: Icon(playerProvider.state.currentViewMode.icon),
                      tooltip: playerProvider.state.currentViewMode.desc,
                      color: Colors.white,
                    ),
                  ],
                )
                ],
              ),
            ),
          );
  }

  void sheet2(
    int index,
    BuildContext context,
    PlayerProvider pp,
    PlayerDataProvider dp,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: appTheme.modalSheetBackgroundColor,
      builder: (context) => CustomControlsBottomSheet(
        index: index,
        dataProvider: dp,
        playerProvider: pp,
      ),
    );
  }

  Widget playBackSpeedDialog(BuildContext context, PlayerProvider pp, PlayerDataProvider dp) {
    final playbackSpeeds = pp.playbackSpeeds;
    return Container(
      height: MediaQuery.of(context).size.height / 2,
      child: AlertDialog(
          backgroundColor: appTheme.modalSheetBackgroundColor,
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  "Speed",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: "Rubik"),
                ),
              ),
              Expanded(
                child: StatefulBuilder(
                  builder: (context, setState) => Container(
                    // height: 230,
                    width: 250,
                    child: ListView.builder(
                      itemCount: playbackSpeeds.length,
                      itemBuilder: (context, index) {
                        return Container(
                          margin: EdgeInsets.only(bottom: 5),
                          clipBehavior: Clip.hardEdge,
                          decoration: BoxDecoration(
                            color: appTheme.backgroundSubColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                pp.setSpeed(playbackSpeeds[index]);
                                setState(() {});
                              },
                              child: Row(
                                children: [
                                  Radio<double>(
                                    value: playbackSpeeds[index],
                                    groupValue: pp.state.speed,
                                    onChanged: (val) {
                                      pp.setSpeed(val ?? 1);
                                      setState(() {});
                                    },
                                  ),
                                  Text(playbackSpeeds[index].toString() + "x"),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              Container(
                margin: EdgeInsets.only(top: 5),
                alignment: Alignment.center,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    "close",
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              )
            ],
          )),
    );
  }
}
