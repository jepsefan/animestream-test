import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/anime/providers/externalAssPreferences.dart';
import 'package:animestream/core/anime/providers/aniyomiExtensionProvider.dart';
import 'package:animestream/ui/models/sources.dart';
import 'package:animestream/core/data/settings.dart';
import 'package:animestream/core/data/types.dart';
import 'package:animestream/ui/models/widgets/slider.dart';
import 'package:animestream/ui/models/widgets/toggleItem.dart';
import 'package:animestream/ui/pages/settingPages/common.dart';
import 'package:animestream/ui/pages/settingPages/subtitle.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PlayerSetting extends StatefulWidget {
  final bool fromWatchPage;
  const PlayerSetting({super.key, this.fromWatchPage = false});

  @override
  State<PlayerSetting> createState() => PlayerSettingState();
}

class PlayerSettingState extends State<PlayerSetting> {
  @override
  void initState() {
    if (widget.fromWatchPage) {
      SystemChrome.setPreferredOrientations(
          [DeviceOrientation.portraitUp, DeviceOrientation.landscapeRight, DeviceOrientation.landscapeLeft]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    super.initState();
    readSettings();
  }

  int? skipDuration;
  int? megaSkipDuration;

  late double skipDurationSliderValue;
  late double megaSkipDurationSliderValue;

  bool loaded = false;
  String assPrimary = '';
  String assSecondary = '';
  String assLanguage = 'en';

  String? preferredQuality;

  late bool enableSuperSpeeds;
  late bool doubleTapToSkip;
  late bool enablePipOnMinimize;
  late bool autoOpEdSkip;
  late bool enableHoldToSpeedUp;
  late bool enablePlayerGestures;

  Future<void> readSettings() async {
    final settings = await Settings().getSettings();
    final primary = await ExternalAssPreferences.primary();
    final secondary = await ExternalAssPreferences.secondary();
    final language = await ExternalAssPreferences.language();
    loaded = true;
    setState(() {
      assPrimary = primary;
      assSecondary = secondary;
      assLanguage = language;
      skipDuration = settings.skipDuration ?? 15;
      megaSkipDuration = settings.megaSkipDuration ?? 85;
      preferredQuality = settings.preferredQuality;
      skipDurationSliderValue = skipDuration!.toDouble();
      megaSkipDurationSliderValue = megaSkipDuration!.toDouble();
      enableSuperSpeeds = settings.enableSuperSpeeds ?? false;
      doubleTapToSkip = settings.doubleTapToSkip ?? true;
      enablePipOnMinimize = settings.enablePipOnMinimize ?? false;
      autoOpEdSkip = settings.autoOpEdSkip ?? false;
      enableHoldToSpeedUp = settings.enableHoldToSpeedUp ?? true;
      enablePlayerGestures = settings.enablePlayerGestures ?? false;
    });
  }

  Future<void> writeSettings(SettingsModal settings) async {
    await Settings().writeSettings(settings);
    setState(() {
      readSettings();
    });
  }

  Set selectedQualitySet = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appTheme.backgroundColor,
      body: SingleChildScrollView(
        child: Container(
          padding: pagePadding(context, bottom: true),
          child: loaded
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    settingPagesTitleHeader(context, "Player"),
                    item(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('External ASS Subtitles', style: textStyle()),
                        const SizedBox(height: 8),
                        for (final selector in ['primary', 'secondary'])
                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            decoration: InputDecoration(labelText:
                                selector == 'primary' ? 'Primary ASS Source' : 'Secondary ASS Source'),
                            value: SourceManager.instance.sources.any((s) =>
                                s.identifier == (selector == 'primary' ? assPrimary : assSecondary))
                                ? (selector == 'primary' ? assPrimary : assSecondary) : '',
                            items: [
                              const DropdownMenuItem(value: '', child: Text('None')),
                              ...SourceManager.instance.sources
                                  .where((s) => AniyomiExtensionProvider.isExtensionId(s.identifier))
                                  .map((s) => DropdownMenuItem(
                                      value: s.identifier,
                                      child: Text(s.name, overflow: TextOverflow.ellipsis))),
                            ],
                            onChanged: (value) async {
                              if (value == null) return;
                              await ExternalAssPreferences.configure(
                                primary: selector == 'primary' ? value : null,
                                secondary: selector == 'secondary' ? value : null);
                              if (mounted) setState(() {
                                if (selector == 'primary') assPrimary = value;
                                else assSecondary = value;
                              });
                            },
                          ),
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(labelText: 'Preferred ASS Language'),
                          value: assLanguage,
                          items: const [
                            DropdownMenuItem(value: 'sv', child: Text('Swedish')),
                            DropdownMenuItem(value: 'en', child: Text('English')),
                            DropdownMenuItem(value: 'ja', child: Text('Japanese')),
                            DropdownMenuItem(value: 'de', child: Text('German')),
                            DropdownMenuItem(value: 'fr', child: Text('French')),
                            DropdownMenuItem(value: 'es', child: Text('Spanish')),
                            DropdownMenuItem(value: 'ar', child: Text('Arabic')),
                            DropdownMenuItem(value: 'any', child: Text('Any language')),
                          ],
                          onChanged: (value) async {
                            if (value == null) return;
                            await ExternalAssPreferences.configure(language: value);
                            if (mounted) setState(() => assLanguage = value);
                          },
                        ),
                        const Text('Enable Ext sub for each anime in Episodes. '
                            'Last used Primary/Secondary is remembered per anime.'),
                      ],
                    )),

                    Container(
                      // padding: EdgeInsets.only(left: 20, right: 20, top: 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          item(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: EdgeInsets.only(bottom: 10),
                                  child: Text(
                                    "Skip duration",
                                    style: textStyle(),
                                  ),
                                ),
                                SliderTheme(
                                  data: SliderThemeData(
                                    thumbColor: appTheme.accentColor,
                                    activeTrackColor: appTheme.accentColor,
                                    inactiveTrackColor: appTheme.textSubColor,
                                    valueIndicatorShape: RoundedSliderValueIndicator(height: 30, width: 35, radius: 5),
                                    valueIndicatorTextStyle: TextStyle(
                                      color: appTheme.backgroundColor,
                                      fontFamily: "NotoSans",
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    valueIndicatorColor: appTheme.accentColor,
                                    trackHeight: 13,
                                    trackShape: MarginedTrack(),
                                    thumbShape: RoundedRectangularThumbShape(width: 10, radius: 5),
                                    activeTickMarkColor: appTheme.backgroundColor,
                                  ),
                                  child: Slider(
                                    onChanged: (val) {
                                      setState(() {
                                        skipDurationSliderValue = val;
                                      });
                                    },
                                    onChangeEnd: (val) {
                                      writeSettings(SettingsModal(skipDuration: skipDurationSliderValue.toInt()));
                                    },
                                    value: skipDurationSliderValue,
                                    divisions: 9,
                                    label: skipDurationSliderValue.round().toString(),
                                    max: 50,
                                    min: 5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          item(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Text(
                                    "Mega skip duration",
                                    style: textStyle(),
                                  ),
                                ),
                                SliderTheme(
                                  data: SliderThemeData(
                                    thumbColor: appTheme.accentColor,
                                    activeTrackColor: appTheme.accentColor,
                                    inactiveTrackColor: appTheme.textSubColor,
                                    valueIndicatorShape: RoundedSliderValueIndicator(height: 30, width: 40, radius: 5),
                                    valueIndicatorTextStyle: TextStyle(
                                      color: appTheme.backgroundColor,
                                      fontFamily: "NotoSans",
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    valueIndicatorColor: appTheme.accentColor,
                                    trackHeight: 13,
                                    thumbShape: RoundedRectangularThumbShape(width: 10, radius: 5),
                                    trackShape: MarginedTrack(),
                                    activeTickMarkColor: appTheme.backgroundColor,
                                  ),
                                  child: Slider(
                                    onChanged: (val) {
                                      setState(() {
                                        megaSkipDurationSliderValue = val;
                                      });
                                    },
                                    onChangeEnd: (val) {
                                      writeSettings(
                                          SettingsModal(megaSkipDuration: megaSkipDurationSliderValue.toInt()));
                                    },
                                    value: megaSkipDurationSliderValue,
                                    divisions: 26,
                                    label: megaSkipDurationSliderValue.round().toString(),
                                    max: 150,
                                    min: 20,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          item(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 20),
                                  child: Text(
                                    "Preferred quality",
                                    style: textStyle(),
                                  ),
                                ),
                                Container(
                                  alignment: Alignment.center,
                                  child: SegmentedButton(
                                    style: SegmentedButton.styleFrom(
                                        backgroundColor: appTheme.backgroundSubColor,
                                        selectedBackgroundColor: appTheme.accentColor,
                                        selectedForegroundColor: appTheme.onAccent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        side: BorderSide(color: appTheme.textSubColor)),
                                    multiSelectionEnabled: false,
                                    showSelectedIcon: false,
                                    onSelectionChanged: (val) {
                                      setState(() {
                                        preferredQuality = val.first;
                                        writeSettings(SettingsModal(preferredQuality: val.first));
                                      });
                                    },
                                    segments: [
                                      segment("360p"),
                                      segment("480p"),
                                      segment("720p"),
                                      segment("1080p"),
                                    ],
                                    selected: <String>{preferredQuality!},
                                  ),
                                ),
                              ],
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              Navigator.of(context)
                                  .push(MaterialPageRoute(builder: (context) => SubtitleSettingPage()));
                            },
                            child: item(
                              // padding: EdgeInsets.only(top: 10, bottom: 10),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Subtitle settings",
                                        style: textStyle(),
                                      ),
                                      Text(
                                        "customize the subtitles",
                                        style: textStyle().copyWith(color: appTheme.textSubColor, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                  Icon(Icons.arrow_forward_ios_rounded)
                                ],
                              ),
                            ),
                          ),
                          ToggleItem(
                              label: "Enable super speeds",
                              value: enableSuperSpeeds,
                              description: "Enable extra player speeds",
                              onTapFunction: () {
                                enableSuperSpeeds = !enableSuperSpeeds;
                                writeSettings(SettingsModal(enableSuperSpeeds: enableSuperSpeeds));
                              }),
                            ToggleItem(
                              onTapFunction: () {
                                doubleTapToSkip = !doubleTapToSkip;
                                writeSettings(SettingsModal(doubleTapToSkip: doubleTapToSkip));
                              },
                              label: "Double tap to seek",
                              description: "Double tap left/right to jump $skipDuration seconds",
                              value: doubleTapToSkip,
                              mobileOnly: true,
                            ),
                          ToggleItem(
                            label: "Auto Picture-in-Picture",
                            description: "Enter PiP automatically when minimized",
                            value: enablePipOnMinimize,
                            onTapFunction: () {
                              enablePipOnMinimize = !enablePipOnMinimize;
                              writeSettings(SettingsModal(enablePipOnMinimize: enablePipOnMinimize));
                            },
                          ),
                          ToggleItem(
                            label: "Auto Op/Ed Skip",
                            description: "Auto skip opening and ending themes",
                            value: autoOpEdSkip,
                            onTapFunction: () {
                              autoOpEdSkip = !autoOpEdSkip;
                              writeSettings(SettingsModal(autoOpEdSkip: autoOpEdSkip));
                            },
                          ),
                          ToggleItem(
                            onTapFunction: () {
                              enableHoldToSpeedUp = !enableHoldToSpeedUp;
                              writeSettings(SettingsModal(enableHoldToSpeedUp: enableHoldToSpeedUp));
                            },
                            label: "Hold to Speed Up",
                            description: "Long press the player to speed up the video",
                            value: enableHoldToSpeedUp,
                          ),
                          ToggleItem(
                            onTapFunction: () {
                              enablePlayerGestures = !enablePlayerGestures;
                              writeSettings(SettingsModal(enablePlayerGestures: enablePlayerGestures));
                            },
                            label: "Player Gestures",
                            description: "Gestures for brightness & volume controls",
                            value: enablePlayerGestures,
                            mobileOnly: true,
                            )
                        ],
                      ),
                    )
                  ],
                )
              : Container(),
        ),
      ),
    );
  }

  Container item({required Widget child}) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 15, 20, 15),
      child: child,
    );
  }

  ButtonSegment segment(String label) {
    return ButtonSegment(
      value: label,
      label: Text(
        label,
        style: TextStyle(
          // color: preferredQuality == label ? appTheme.backgroundColor : appTheme.accentColor,
          fontSize: 16,
          fontFamily: "NotoSans",
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  void dispose() {
    if (widget.fromWatchPage) {
      SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeRight, DeviceOrientation.landscapeLeft]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setPreferredOrientations(
          [DeviceOrientation.portraitUp, DeviceOrientation.landscapeRight, DeviceOrientation.landscapeLeft]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    super.dispose();
  }
}
