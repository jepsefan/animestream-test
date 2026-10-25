import 'package:animestream/core/network/sourceVerificationSession.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// User completes the source's normal browser challenge manually.
/// The page returns true only once the same source API accepts the session.
class SourceVerificationPage extends StatefulWidget {
  const SourceVerificationPage({super.key});

  @override
  State<SourceVerificationPage> createState() => _SourceVerificationPageState();
}

class _SourceVerificationPageState extends State<SourceVerificationPage> {
  bool checking = false;
  String message = 'Complete the verification in the browser.';
  bool finished = false;

  Future<void> _check() async {
    if (checking || finished) return;
    setState(() { checking = true; message = 'Checking source access...'; });
    try {
      final uri = WebUri('https://animepahe.pw/');
      final cookies = await CookieManager.instance().getCookies(url: uri);
      await SourceVerificationSession.instance.saveCookies({
        for (final cookie in cookies) cookie.name: cookie.value,
      });
      final accepted = await SourceVerificationSession.instance.probe();
      if (!mounted) return;
      if (accepted) {
        finished = true;
        Navigator.of(context).pop(true);
      } else {
        setState(() => message =
          'Verification is not accepted by the source API. Complete the challenge and try again.');
      }
    } catch (_) {
      if (mounted) setState(() => message = 'Could not check verification. Try again.');
    } finally {
      if (mounted && !finished) setState(() => checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify AnimePahe')),
      body: Column(children: [
        Expanded(child: InAppWebView(
          initialUrlRequest: URLRequest(url: WebUri('https://animepahe.pw/')),
          onLoadStop: (controller, url) {
            if (url?.host == SourceVerificationSession.host) _check();
          },
        )),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: checking ? null : _check,
              icon: const Icon(Icons.verified_user_outlined),
              label: Text(checking ? 'Checking...' : 'Check verification'),
            ),
          ]),
        ),
      ]),
    );
  }
}
