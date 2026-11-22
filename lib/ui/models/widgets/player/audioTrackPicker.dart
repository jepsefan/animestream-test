import 'package:animestream/ui/models/playerControllers/betterPlayer.dart';
import 'package:animestream/ui/models/playerControllers/fvp.dart';
import 'package:animestream/ui/models/providers/playerProvider.dart';
import 'package:flutter/material.dart';

/// One list of *actual* Media3 audio tracks for both HLS and MKV.
/// Extension-provided HLS URLs are not shown a second time and selecting a
/// track uses Media3 directly without rebuilding or restarting the video.
class AudioTrackPicker {
  static String _language(String raw) {
    final value = raw.toLowerCase().trim().split(RegExp(r'[-_ ]')).first;
    switch (value) {
      case 'ja': case 'jp': case 'jpn': case 'japanese': case 'native':
        return 'Japanese';
      case 'en': case 'eng': case 'english': return 'English';
      case 'sv': case 'swe': case 'swedish': return 'Swedish';
      case 'fr': case 'fre': case 'fra': case 'french': return 'French';
      case 'de': case 'deu': case 'ger': case 'german': return 'German';
      case 'es': case 'spa': case 'spanish': return 'Spanish';
      case 'ar': case 'ara': case 'arabic': return 'Arabic';
      case 'zh': case 'zho': case 'chi': case 'chinese': return 'Chinese';
      case 'ko': case 'kor': case 'korean': return 'Korean';
      default: return '';
    }
  }

  static String _title(Map<String, dynamic> track) {
    final language = track['language']?.toString() ?? '';
    final label = track['label']?.toString() ?? '';
    // Media3 may expose manifest NAME=Native_1 / English_2.
    final clean = label.replaceFirst(RegExp(r'_\d+$'), '').trim();
    final recognized = _language(language);
    if (recognized.isNotEmpty) return recognized;
    final fromLabel = _language(clean);
    if (fromLabel.isNotEmpty) return fromLabel;
    return clean.isEmpty ? 'Audio' : clean;
  }

  static Future<void> show(BuildContext context, PlayerProvider player) async {
    final wrapper = player.controller;
    final tracks = <Map<String, dynamic>>[];
    try {
      if (wrapper is BetterPlayerWrapper) {
        tracks.addAll(await wrapper.getEmbeddedAudioTracks());
      } else if (wrapper is FvpWrapper && wrapper.controller.isAudioTrackSupportAvailable()) {
        tracks.addAll([
          for (final track in await wrapper.controller.getAudioTracks())
            {'id': track.id, 'label': track.label, 'language': track.language, 'selected': track.isSelected},
        ]);
      }
    } catch (_) {
      // Some backends cannot enumerate tracks for the current stream.
    }
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SizedBox(
          height: (MediaQuery.sizeOf(sheetContext).height * 0.62)
              .clamp(230.0, 560.0),
          child: Column(children: [
            const Padding(
              padding: EdgeInsets.all(18),
              child: Text('Audio Tracks',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            ),
            Expanded(child: ListView(children: [
              for (final track in tracks)
                ListTile(
                  leading: const Icon(Icons.audiotrack),
                  title: Text(_title(track)),
                  selected: track['selected'] == true,
                  onTap: () async {
                    try {
                      if (wrapper is BetterPlayerWrapper) {
                        if (!await wrapper.selectEmbeddedAudioTrack(track)) {
                          throw StateError('Track unavailable');
                        }
                      } else if (wrapper is FvpWrapper) {
                        await wrapper.controller.selectAudioTrack(track['id'] as String);
                      }
                      if (sheetContext.mounted) Navigator.pop(sheetContext);
                    } catch (_) {
                      if (sheetContext.mounted) {
                        ScaffoldMessenger.of(sheetContext).showSnackBar(
                          const SnackBar(content:
                              Text('Could not select this audio track')),
                        );
                      }
                    }
                  },
                ),
              if (tracks.isEmpty)
                const ListTile(title: Text('No selectable audio tracks found')),
            ])),
          ]),
        ),
      ),
    );
  }
}
