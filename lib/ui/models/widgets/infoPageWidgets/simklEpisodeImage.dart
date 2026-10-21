import 'package:animestream/core/database/simkl/episodeArtwork.dart';
import 'package:flutter/material.dart';

/// Renders SIMKL thumbnails from the existing shared CacheManager.
class SimklEpisodeImage extends StatelessWidget {
  const SimklEpisodeImage({super.key, required this.url, required this.fallback,
      this.fit = BoxFit.cover, this.width, this.height});
  final String? url;
  final String fallback;
  final BoxFit fit;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final u = url;
    final valid = u != null && u.isNotEmpty;
    Widget defaultImage() => Image.network(fallback,
        fit: fit, width: width, height: height);
    if (!valid) return defaultImage();
    if (!u.contains('wsrv.nl/?url=') || !u.contains('simkl.in%2Fepisodes%2F')) {
      return Image.network(u, fit: fit, width: width, height: height,
          errorBuilder: (context, error, stack) => defaultImage());
    }
    return FutureBuilder(
      future: SimklEpisodeArtwork.instance.imageBytes(u),
      builder: (context, snapshot) {
        final data = snapshot.data;
        if (data == null || data.isEmpty) return defaultImage();
        return Image.memory(data, fit: fit, width: width, height: height,
            errorBuilder: (context, error, stack) => defaultImage());
      },
    );
  }
}
