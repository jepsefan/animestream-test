import 'package:animestream/ui/models/playerControllers/betterPlayer.dart';
import 'package:animestream/ui/models/providers/playerDataProvider.dart';
import 'package:animestream/ui/models/providers/playerProvider.dart';
import 'package:flutter/material.dart';

/// Present actual embedded MKV/Media3 tracks and extension-provided HLS audio.
/// No source URL or signed header is shown in the UI.
class AudioTrackPicker {
  static Future<void> show(BuildContext context,
      PlayerDataProvider data, PlayerProvider player) async {
    final embedded = player.controller is BetterPlayerWrapper
        ? await (player.controller as BetterPlayerWrapper).getEmbeddedAudioTracks()
        : <Map<String, dynamic>>[];
    if (!context.mounted) return;
    final external = data.state.currentStream.externalAudioTracks;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SizedBox(
          height: (MediaQuery.sizeOf(sheetContext).height * 0.62).clamp(230.0, 560.0),
          child: Column(children: [
            const Padding(
              padding: EdgeInsets.all(18),
              child: Text('Audio Tracks',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            ),
            Expanded(child: ListView(children: [
              if (external.isNotEmpty) ...[
                const ListTile(title: Text('External HLS audio'),
                    subtitle: Text('Restarts video at the same position')),
                for (final audio in external)
                  ListTile(
                    leading: const Icon(Icons.language),
                    title: Text(audio.label.isEmpty ? audio.language : audio.label),
                    subtitle: Text(audio.language),
                    onTap: () async {
                      try {
                        final success = await player.restartWithExternalAudio(
                            data.state.currentStream, audio.url);
                        if (!success) throw StateError('Audio switching not supported for this stream');
                        final track = data.availableAudioTracks
                            .where((a) => a.url == audio.url).firstOrNull;
                        if (track != null) data.updateCurrentAudioTrack(track);
                        if (sheetContext.mounted) Navigator.pop(sheetContext);
                      } catch (_) {
                        if (sheetContext.mounted) {
                          ScaffoldMessenger.of(sheetContext).showSnackBar(
                            const SnackBar(content: Text(
                                'Could not change external audio for this stream')));
                        }
                      }
                    },
                  ),
              ],
              if (embedded.isNotEmpty) ...[
                const ListTile(title: Text('Embedded audio (MKV / Media3)')),
                for (final track in embedded)
                  ListTile(
                    leading: const Icon(Icons.audiotrack),
                    title: Text(track['label']?.toString() ?? 'Audio'),
                    subtitle: Text(track['language']?.toString() ?? ''),
                    onTap: () async {
                      try {
                        final success = await (player.controller as BetterPlayerWrapper)
                            .selectEmbeddedAudioTrack(track);
                        if (!success) throw StateError('Native track not available');
                        if (sheetContext.mounted) Navigator.pop(sheetContext);
                      } catch (_) {
                        if (sheetContext.mounted) {
                          ScaffoldMessenger.of(sheetContext).showSnackBar(
                            const SnackBar(content: Text(
                                'Could not select this embedded audio track')));
                        }
                      }
                    },
                  ),
              ],
              if (external.isEmpty && embedded.isEmpty)
                const ListTile(title: Text('No selectable audio tracks found'),
                    subtitle: Text('The current file or player has not exposed additional audio.')),
            ])),
          ]),
        ),
      ),
    );
  }
}
