import 'package:animestream/ui/models/completedCoverStatus.dart';
import 'package:flutter/material.dart';

/// Draws a subtle tint over a completed anime's poster only.
/// Does not intercept taps, focus, or rating badges.
class CompletedCoverOverlay extends StatefulWidget {
  final int animeId;
  final Widget child;
  const CompletedCoverOverlay({super.key, required this.animeId, required this.child});

  @override
  State<CompletedCoverOverlay> createState() => _CompletedCoverOverlayState();
}

class _CompletedCoverOverlayState extends State<CompletedCoverOverlay> {
  final status = CompletedCoverStatus.instance;

  @override
  void initState() {
    super.initState();
    status.addListener(_refresh);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) status.ensureLoaded();
    });
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    status.removeListener(_refresh);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(fit: StackFit.passthrough, children: [
      widget.child,
      if (status.contains(widget.animeId))
        const Positioned.fill(
          child: IgnorePointer(
            child: ColoredBox(color: Color(0x66000000)),
          ),
        ),
    ]);
  }
}
