import 'package:animestream/ui/models/bottomSheets/customControlsSheet.dart';
import 'package:animestream/ui/models/providers/playerDataProvider.dart';
import 'package:animestream/ui/models/providers/playerProvider.dart';
import 'package:animestream/ui/models/widgets/player/mobileControls/bottomControls.dart';
import 'package:animestream/ui/models/widgets/player/mobileControls/topControls.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/commons/enums.dart';
import 'package:animestream/ui/models/snackBar.dart';

class MobileControls extends StatefulWidget {
  const MobileControls({
    super.key,
  });

  @override
  State<MobileControls> createState() => _MobileControlsState();
}

class _MobileControlsState extends State<MobileControls> {
  final FocusNode _playPauseFocusNode = FocusNode(debugLabel: 'video_play_pause');
  final FocusNode _bottomControlsFocusNode =
      FocusNode(debugLabel: 'video_bottom_controls');
  final FocusNode _timelineFocusNode =
      FocusNode(debugLabel: 'video_timeline');
  bool _wasControlsVisible = false;

  bool startedLoadingNext = false;

  bool calledAutoNext = false;

  @override
  void initState() {
    super.initState();
    _timelineFocusNode.addListener(_handleTimelineFocusChanged);
  }

  void _handleTimelineFocusChanged() {
    if (mounted) setState(() {});
  }

  int? skipDuration = currentUserSettings?.skipDuration ?? 10;
  int? megaSkipDuration = currentUserSettings?.megaSkipDuration ?? 85;

  Future<void>? _pendingSeek = null; 

  @override
  void dispose() {
    _playPauseFocusNode.dispose();
    _bottomControlsFocusNode.dispose();
    _timelineFocusNode.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  KeyEventResult _keyListenerEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    print("Key pressed: ${event.logicalKey.keyLabel}");
    print(event);
    switch (event.logicalKey) {
      case LogicalKeyboardKey.mediaPlayPause:
      case LogicalKeyboardKey.space:
        (provider.controller.isPlaying ?? false)
            ? provider.controller.pause()
            : provider.controller.play();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.mediaPause:
        provider.controller.pause();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.mediaPlay:
        provider.controller.play();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.mediaTrackNext:
        if (dataProvider.state.currentEpIndex + 1 == dataProvider.epLinks.length) {
          return KeyEventResult.handled;
        }
        provider.playPreloadedEpisode(dataProvider);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.mediaTrackPrevious:
        if (dataProvider.state.currentEpIndex == 0) {
          return KeyEventResult.handled;
        }
        showSheet(
            context,
            CustomControlsBottomSheet(
                index: dataProvider.state.currentEpIndex - 1, dataProvider: dataProvider, playerProvider: provider));
        return KeyEventResult.handled;
      case LogicalKeyboardKey.mediaFastForward:
        provider.fastForward(skipDuration ?? 10);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.mediaRewind:
        provider.fastForward(-(skipDuration ?? 10));
        return KeyEventResult.handled;
      case LogicalKeyboardKey.select:
      case LogicalKeyboardKey.enter:
      case LogicalKeyboardKey.numpadEnter:
        {
          // On Android TV, only D-pad center/OK should open the player overlay.
          // Touch/mouse visibility handling is independent in Watch/GestureOverlay.
          if (!provider.state.controlsVisible) {
            provider.toggleControlsVisibility(action: true);
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        }
      case LogicalKeyboardKey.arrowUp:
      case LogicalKeyboardKey.arrowDown:
      case LogicalKeyboardKey.arrowLeft:
      case LogicalKeyboardKey.arrowRight:
        {
          // Do not reveal controls from D-pad directions while hidden.
          // Left/right are allowed to bubble to Watch, where they perform the
          // existing seek +/- skipDuration and show the skip animation.
          return KeyEventResult.ignored;
        }

      default:
        print("Unhandled key: ${event.logicalKey.keyLabel} (${event.logicalKey.keyId}) type: ${event.deviceType.name}");
        return KeyEventResult.ignored;
    }
  }

  late PlayerProvider provider;
  late PlayerDataProvider dataProvider;

  @override
  Widget build(BuildContext context) {
    dataProvider = context.watch<PlayerDataProvider>();
    provider = context.watch<PlayerProvider>();

    final controlsVisible = provider.state.controlsVisible;
    if (controlsVisible &&
        !_wasControlsVisible &&
        !dataProvider.state.controlsLocked) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _playPauseFocusNode.canRequestFocus) {
          _playPauseFocusNode.requestFocus();
        }
      });
    }
    _wasControlsVisible = controlsVisible;

    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) => _keyListenerEvent(event),
      child: OrientationBuilder(
        builder: (context, orientation) {
          double LRpadding = 30;
          if (orientation == Orientation.portrait) LRpadding = 10;
          return Padding(
            padding: EdgeInsets.only(top: 15, left: LRpadding, right: LRpadding, bottom: 5),
            child: Column(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TopControls(provider: provider, dataProvider: dataProvider, context: context),
                      Expanded(
                        child: dataProvider.state.controlsLocked ? lockedCenterControls() : centerControls(context),
                      ),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      dataProvider.state.currentTimeStamp,
                                      style: TextStyle(color: Colors.white, fontFamily: 'NunitoSans'),
                                    ),
                                    const Text(
                                      " / ",
                                      style: TextStyle(color: Colors.white, fontFamily: 'NunitoSans'),
                                    ),
                                    Text(
                                      dataProvider.state.maxTimeStamp,
                                      style: TextStyle(color: Colors.white, fontFamily: 'NunitoSans'),
                                    ),
                                  ],
                                ),
                                if (megaSkipDuration != null)
                                  dataProvider.state.controlsLocked ? Container() : megaSkipButton(),
                              ],
                            ),
                            Container(
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                height: 20,
                                child: IgnorePointer(
                                  ignoring: dataProvider.state.controlsLocked,
                                  child: Container(
                                    child: Focus(
                                      focusNode: _timelineFocusNode,
                                      onKeyEvent: (node, event) {
                                        if (event is! KeyDownEvent) {
                                          return KeyEventResult.ignored;
                                        }

                                        if (event.logicalKey ==
                                            LogicalKeyboardKey.arrowDown) {
                                          _bottomControlsFocusNode.requestFocus();
                                          return KeyEventResult.handled;
                                        }

                                        final step =
                                            currentUserSettings?.skipDuration ?? 10;
                                        if (event.logicalKey ==
                                            LogicalKeyboardKey.arrowLeft) {
                                          provider.fastForward(-step);
                                          return KeyEventResult.handled;
                                        }
                                        if (event.logicalKey ==
                                            LogicalKeyboardKey.arrowRight) {
                                          provider.fastForward(step);
                                          return KeyEventResult.handled;
                                        }

                                        return KeyEventResult.ignored;
                                      },
                                      child: SliderTheme(
                                        data: SliderThemeData(
                                          trackHeight:
                                              _timelineFocusNode.hasFocus ? 2.4 : 1.3,
                                          thumbColor: appTheme.accentColor,
                                          activeTrackColor: appTheme.accentColor,
                                          inactiveTrackColor:
                                              const Color.fromARGB(255, 121, 121, 121),
                                          secondaryActiveTrackColor:
                                              const Color.fromARGB(255, 167, 167, 167),
                                          thumbShape: dataProvider.state.controlsLocked
                                              ? SliderComponentShape.noThumb
                                              : RoundSliderThumbShape(
                                                  enabledThumbRadius:
                                                      _timelineFocusNode.hasFocus ? 8 : 6,
                                                  elevation:
                                                      _timelineFocusNode.hasFocus ? 8 : 1,
                                                  pressedElevation:
                                                      _timelineFocusNode.hasFocus ? 12 : 6,
                                                ),
                                          trackShape: EdgeToEdgeTrackShape(),
                                          overlayShape: _timelineFocusNode.hasFocus
                                              ? const RoundSliderOverlayShape(
                                                  overlayRadius: 16,
                                                )
                                              : SliderComponentShape.noOverlay,
                                          overlayColor: appTheme.accentColor.withAlpha(
                                            _timelineFocusNode.hasFocus ? 90 : 0,
                                          ),
                                        ),
                                        child: Slider(
                                          value: dataProvider.state.sliderValue.toDouble(),
                                          secondaryTrackValue:
                                              provider.controller.buffered?.toDouble(),
                                          onChanged: (val) {
                                            setState(() {
                                              _pendingSeek = provider.controller
                                                  .seekTo(Duration(seconds: val.toInt()));
                                            });
                                          },
                                          onChangeStart: (value) {
                                            provider.controller.pause();
                                          },
                                          onChangeEnd: (value) async {
                                            if (_pendingSeek != null) {
                                              await _pendingSeek;
                                            }

                                            // just to make sure its on the same page...
                                            await provider.controller
                                                .seekTo(Duration(seconds: value.toInt()));

                                            await provider.controller.play();
                                          },
                                          min: 0,
                                          max: (provider.controller.duration ?? 0) / 1000,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            BottomControls(firstFocusNode: _bottomControlsFocusNode),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  ElevatedButton megaSkipButton() {
    int posInSec = (provider.controller.position! / 1000).toInt();
    final isAtOp = dataProvider.state.opSkip != null &&
        posInSec >= dataProvider.state.opSkip!.start &&
        posInSec <= dataProvider.state.opSkip!.end;
    final isAtEd = dataProvider.state.edSkip != null &&
        posInSec >= dataProvider.state.edSkip!.start &&
        posInSec <= dataProvider.state.edSkip!.end;

    return ElevatedButton(
      onPressed: () {
        provider.fastForward(isAtOp
            ? dataProvider.state.opSkip!.end - posInSec
            : isAtEd
                ? dataProvider.state.edSkip!.end - posInSec
                : megaSkipDuration!);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Color.fromARGB(68, 0, 0, 0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: appTheme.accentColor),
        ),
      ),
      child: Container(
        height: 50,
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 5),
              child: Text(
                isAtOp
                    ? "Skip Op"
                    : isAtEd
                        ? "Skip Ed"
                        : "+$megaSkipDuration",
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: "Rubik",
                  fontSize: 17,
                ),
              ),
            ),
            Icon(
              Icons.fast_forward_rounded,
              color: Colors.white,
            )
          ],
        ),
      ),
    );
  }

  Container lockedCenterControls() {
    return Container(
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (provider.controller.isBuffering ?? false)
            Container(
              width: 40,
              height: 40,
              child: Center(
                child: CircularProgressIndicator(
                  color: appTheme.accentColor,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Container centerControls(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Material(
            color: Colors.transparent,
            child: Container(
              margin: EdgeInsets.only(right: 5),
              height: 65,
              width: 65,
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () async {
                  if (dataProvider.state.currentEpIndex == 0) return floatingSnackBar("Already on the first episode");
                  showSheet(
                    context,
                    CustomControlsBottomSheet(
                      index: dataProvider.state.currentEpIndex - 1,
                      dataProvider: dataProvider,
                      playerProvider: provider,
                    ),
                  );
                },
                child: Icon(
                  Icons.skip_previous_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
          ),
          // ),
          Material(
            color: Colors.transparent,
            child: Container(
              height: 65,
              width: 65,
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  provider.fastForward(skipDuration != null ? -skipDuration! : -10);
                },
                child: Icon(
                  Icons.fast_rewind_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
          ),
          Container(
            // padding: EdgeInsets.only(left: 35, right: 35),
            child: !(provider.controller.isBuffering ?? false)
                ? Material(
                    color: Colors.transparent,
                    child: Container(
                      margin: EdgeInsets.only(left: 5, right: 5),
                      height: 65,
                      width: 65,
                      child: InkWell(
                        focusNode: _playPauseFocusNode,
                        focusColor: Colors.white24,
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          if (provider.state.playerState == PlayerState.playing) {
                            // playPause = Icons.play_arrow_rounded;
                            provider.controller.pause();
                          } else {
                            // playPause = Icons.pause_rounded;
                            provider.controller.play();
                          }
                        },
                        child: Icon(
                          provider.state.playerState == PlayerState.playing
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 45,
                        ),
                      ),
                    ),
                  )
                : Container(
                    width: 65,
                    height: 65,
                    margin: EdgeInsets.only(left: 5, right: 5),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: appTheme.accentColor,
                      ),
                    ),
                  ),
          ),
          Material(
            color: Colors.transparent,
            child: Container(
              height: 65,
              width: 65,
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  provider.fastForward(skipDuration ?? 10);
                },
                child: Icon(
                  Icons.fast_forward_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: Container(
              margin: EdgeInsets.only(left: 5),
              height: 65,
              width: 65,
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () async {
                  //get next episode sources!
                  if (dataProvider.state.currentEpIndex + 1 == dataProvider.epLinks.length)
                    return floatingSnackBar("You are already in the final episode!");
                  if (dataProvider.state.preloadedSources.isNotEmpty) {
                    print("from preload");
                    provider.playPreloadedEpisode(dataProvider);
                  } else {
                    showSheet(
                      context,
                      CustomControlsBottomSheet(
                        index: dataProvider.state.currentEpIndex + 1,
                        dataProvider: dataProvider,
                        playerProvider: provider,
                      ),
                    );
                  }
                },
                child: Icon(
                  Icons.skip_next_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
          ),
          // ),
        ],
      ),
    );
  }

  void showSheet(BuildContext context, Widget child) => showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: appTheme.modalSheetBackgroundColor,
      context: context,
      builder: (BuildContext context) {
        return child;
      });
}

class EdgeToEdgeTrackShape extends RoundedRectSliderTrackShape {
  // Override getPreferredRect to adjust the track's dimensions
  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final double trackHeight = sliderTheme.trackHeight ?? 2.0;
    final double trackWidth = parentBox.size.width;
    final double trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2;
    return Rect.fromLTWH(offset.dx, trackTop, trackWidth, trackHeight);
  }
}
