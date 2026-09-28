import 'package:animestream/core/app/runtimeDatas.dart';
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
                        playerProvider.toggleSubs();
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
                      tooltip: "Subtitles",
                      icon: Icon(
                        !playerProvider.state.showSubs ? Icons.subtitles_outlined : Icons.subtitles_rounded,
                        color: Colors.white,
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
