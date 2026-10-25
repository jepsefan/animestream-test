import 'package:animestream/core/app/logging.dart';
import 'package:animestream/core/commons/extractQuality.dart';
import 'package:animestream/ui/models/playerControllers/videoController.dart';
import 'package:animestream/ui/models/widgets/player/playerUtils.dart';
import 'package:better_player/better_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BetterPlayerWrapper implements VideoController {
  late BetterPlayerController controller = BetterPlayerController(_config);

  final List<VoidCallback?> listeners = [];

  final key = GlobalKey();

  static final _config = BetterPlayerConfiguration(
    aspectRatio: 16 / 9,
    fit: BoxFit.contain,
    expandToFill: true,
    autoPlay: true,
    errorBuilder: (context, errorMessage) {
      return Center(
          child: Text(
        "Whoops! Ran into some errors playing this video!\nDetails:\n$errorMessage",
        style: TextStyle(fontSize: 20),
      ));
    },
    eventListener: (ev) {
      if (ev.betterPlayerEventType == BetterPlayerEventType.exception) {
        Logs.player.log("[PLAYER] Oooooooh! We've got some issues!!! \n${ev.parameters}");
      }
    },
    autoDispose: true,
    controlsConfiguration: BetterPlayerControlsConfiguration(
      showControls: false,
    ),
  );

  @override
  Future<void> initiateVideo(String url, {Map<String, String>? headers, bool offline = false, bool shareWebViewCookies = false}) async {
    final ds = offline
        ? BetterPlayerDataSource.file(url)
        : await dataSourceConfig(url, headers: headers,
            shareWebViewCookies: shareWebViewCookies);
    await controller.setupDataSource(ds);
  }

  @override
  bool? get isBuffering => controller.isBuffering();

  @override
  bool? get isPlaying => controller.isPlaying();

  @override
  int? get position => controller.videoPlayerController?.value.position.inMilliseconds;

  @override
  int? get duration => controller.videoPlayerController?.value.duration?.inMilliseconds;

  @override
  int? get buffered => controller.videoPlayerController?.value.buffered.lastOrNull?.end.inSeconds;

  @override
  double? get volume => controller.videoPlayerController?.value.volume;

  @override
  String? get activeMediaUrl => controller.betterPlayerDataSource?.url;

  @override
  bool? get isInitialized => controller.isVideoInitialized();

  @override
  Future<void> pause() {
    return controller.pause();
  }

  @override
  Future<void> play() {
    return controller.play();
  }

  @override
  Future<void> seekTo(Duration duration) {
    return controller.seekTo(duration);
  }

  @override
  Future<void> setSpeed(double speed) async {
    controller.setSpeed(speed);
  }

  @override
  void dispose() {
    return controller.dispose();
  }

  bool get stableSubtitleRenderer =>
      controller.subtitleRenderer.value == BetterPlayerSubtitleRenderer.stableOverlap;

  void setSubtitleRenderer(BetterPlayerSubtitleRenderer renderer) {
    controller.setSubtitleRenderer(renderer);
  }

  @override
  Widget getWidget() {
    return BetterPlayer(controller: controller, key: key);
  }

  @override
  void addListener(VoidCallback cb) {
    listeners.add(cb);
    controller.videoPlayerController?.addListener(cb);
  }

  @override
  void setFit(BoxFit fit) {
    return controller.setOverriddenFit(fit);
  }

  @override
  Future<void> setVolume(double volume) {
    return controller.setVolume(volume);
  }

  @override
  void removeListener(VoidCallback cb) {
    return controller.videoPlayerController?.removeListener(cb);
  }

  @override
  Future<void> setPip(bool value) async {
    if (value)
      controller.enablePictureInPicture(key);
    else
      controller.disablePictureInPicture();
  }

  /// Native Media3 track list also includes MKV-contained audio languages.
  /// Uses the current Better Player texture, not a global player instance.
  Future<List<Map<String, dynamic>>> getEmbeddedAudioTracks() async {
    final textureId = controller.videoPlayerController?.textureId;
    if (textureId == null) return const [];
    final raw = await const MethodChannel('better_player_channel')
        .invokeMethod<List<dynamic>>('getEmbeddedAudioTracks', {'textureId': textureId});
    return (raw ?? const []).whereType<Map>().map((e) =>
        Map<String, dynamic>.from(e)).toList();
  }

  Future<bool> selectEmbeddedAudioTrack(Map<String, dynamic> track) async {
    final textureId = controller.videoPlayerController?.textureId;
    if (textureId == null) return false;
    return await const MethodChannel('better_player_channel').invokeMethod<bool>(
      'selectEmbeddedAudioTrack', {
        'textureId': textureId,
        'renderer': track['renderer'],
        'group': track['group'],
        'track': track['track'],
      },
    ) ?? false;
  }

  @override
  Future<void> setAudioTrack(AudioStream aud) async {
    final renditions = controller.betterPlayerAsmsAudioTracks;
    if (renditions == null || renditions.isEmpty) {
      Logs.player.log('HLS audio rendition selection unavailable in player');
      return;
    }
    final toLang = _asToAsmsAudioTrack(aud);
    print("Setting to ${toLang.language}, ${toLang.id}");
    return controller.setAudioTrack(toLang);
  }

  @override
  void setQuality(QualityStream qs) async {
    final track = _qsToAsmsTrack(qs);
    if (track == null) {
      return print("[ERROR] No matching track found for '${qs.resolution}', cannot set quality.");
    }

    print("Found matching track: $track");
    return controller.setTrack(track);
  }

  BetterPlayerAsmsTrack? _qsToAsmsTrack(QualityStream qs) {
    try {
      return controller.betterPlayerAsmsTracks.firstWhere((element) {
        final resMatch = element.height == (int.tryParse(qs.resolution.split("x").last) ?? 0);
        final bwMatch = element.bitrate == (qs.bandwidth ?? 0);
        return resMatch && bwMatch;
      }, orElse: () {
        print("[ERROR] No matching track found for '${qs.resolution}', defaulting to first track.");
        return controller.betterPlayerAsmsTracks.first;
      });
    } catch (err) {
      return null;
    }
    // return BetterPlayerAsmsTrack('', int.tryParse(qs.resolution.split("x").first) ?? 0,
    //     int.tryParse(qs.resolution.split("x").last) ?? 0, qs.bandwidth ?? 0, 0, '', '');
  }

  BetterPlayerAsmsAudioTrack _asToAsmsAudioTrack(AudioStream aud) {
    return controller.betterPlayerAsmsAudioTracks!.firstWhere(
      (element) => element.label == aud.name && element.language == aud.language,
      orElse: () => controller.betterPlayerAsmsAudioTracks!.firstWhere(
        (element) => element.language == aud.language,
        orElse: () => controller.betterPlayerAsmsAudioTracks!.first,
      ),
    );
  }
}
