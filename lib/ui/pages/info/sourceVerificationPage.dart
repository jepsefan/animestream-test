import 'package:animestream/core/anime/providers/aniyomiExtensionBridge.dart';
import 'package:animestream/core/anime/providers/extensionVerificationOutcome.dart';
import 'package:animestream/core/app/values.dart';
import 'package:animestream/core/network/sourceVerificationSession.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// Manually verify in a WebView, then confirm the ACTUAL selected network
/// client works. Extension cookies remain in Android's CookieManager and
/// are consumed by the native Aniyomi OkHttp CookieJar.
class SourceVerificationPage extends StatefulWidget {
  final String? extensionPackage;
  final int? extensionSourceId;
  final String? extensionSourceName;
  final String? extensionLanguage;
  final String searchQuery;

  const SourceVerificationPage({
    super.key,
    this.extensionPackage,
    this.extensionSourceId,
    this.extensionSourceName,
    this.extensionLanguage,
    this.searchQuery = 'naruto',
  });

  @override
  State<SourceVerificationPage> createState() => _SourceVerificationPageState();
}

class _SourceVerificationPageState extends State<SourceVerificationPage> {
  bool checking = false;
  bool finished = false;
  String message = 'Complete the website verification, then tap Check verification.';
  String host = SourceVerificationSession.host;
  String userAgent = AppValues.defaultClientUserAgent;
  bool initialized = false;
  bool supported = true;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    if (widget.extensionPackage != null) {
      try {
        final data = await AniyomiExtensionBridge.extensionVerificationInfo(
          widget.extensionPackage!,
          sourceId: widget.extensionSourceId!,
          sourceName: widget.extensionSourceName!,
          sourceLanguage: widget.extensionLanguage!,
        );
        final candidate = data['host']?.toString().toLowerCase() ?? '';
        final valid = RegExp(r'^(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z]{2,24}$');
        if (data['status'] == 'ok' && valid.hasMatch(candidate)) {
          host = candidate;
          final ua = data['userAgent']?.toString() ?? '';
          if (ua.isNotEmpty) userAgent = ua;
        } else {
          supported = false;
          message = 'This source has no supported HTTPS verification website.';
        }
      } catch (_) {
        supported = false;
        message = 'Could not load the selected extension website.';
      }
    }
    if (mounted) setState(() => initialized = true);
  }

  String _diagnosis(Map<String, dynamic> data) {
    final diagnostics = (data['networkDiagnostics'] as List?) ?? const [];
    final parts = <String>[];
    for (final item in diagnostics.whereType<Map>()) {
      final hostName = item['host']?.toString() ?? '';
      if (hostName != host && !hostName.endsWith('.$host')) continue;
      final status = item['status']?.toString() ?? 'unknown';
      if (const {'200', '403', '429', '503', 'network_error'}.contains(status)) {
        parts.add('$hostName: $status');
      }
    }
    return parts.isEmpty ? 'Source search: ${data['status'] ?? 'unknown'}'
        : parts.toSet().join(' • ');
  }

  Future<void> _check() async {
    if (checking || finished || !initialized || !supported) return;
    setState(() { checking = true; message = 'Checking source access...'; });
    try {
      final bool accepted;
      String diagnostic = '';
      if (widget.extensionPackage != null) {
        final result = await AniyomiExtensionBridge.testExtensionSearch(
          widget.extensionPackage!,
          widget.searchQuery.isEmpty ? 'naruto' : widget.searchQuery,
          sourceId: widget.extensionSourceId,
          sourceName: widget.extensionSourceName,
          sourceLanguage: widget.extensionLanguage,
        );
        final outcome = extensionVerificationOutcome(result);
        accepted = outcome == ExtensionVerificationOutcome.matchFound;
        diagnostic = switch (outcome) {
          ExtensionVerificationOutcome.noTitleResults =>
            'Source search completed, but this title was not found in the catalogue. '
            'Website verification alone cannot add a missing title. '
            'Try Manual Search with a title listed on this source',
          ExtensionVerificationOutcome.unrelatedTitleResults =>
            'The source returned results unrelated to this title. '
            'Try Manual Search to select an exact match',
          ExtensionVerificationOutcome.blockedOrFailed => _diagnosis(result),
          ExtensionVerificationOutcome.matchFound => 'Source search completed',
        };
      } else {
        final url = WebUri('https://$host/');
        final cookies = await CookieManager.instance().getCookies(url: url);
        await SourceVerificationSession.instance.saveCookies({
          for (final cookie in cookies) cookie.name: cookie.value,
        });
        accepted = await SourceVerificationSession.instance.probe();
        diagnostic = 'Built-in source API test';
      }
      if (!mounted) return;
      if (accepted) {
        finished = true;
        Navigator.of(context).pop(true);
      } else {
        setState(() => message =
            '$diagnostic.');
      }
    } catch (_) {
      if (mounted) setState(() => message =
          'The source test failed. Complete verification and try again.');
    } finally {
      if (mounted && !finished) setState(() => checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify source')),
      body: !initialized
          ? const Center(child: CircularProgressIndicator())
          : !supported
              ? Center(child: Padding(padding: const EdgeInsets.all(20), child: Text(message)))
              : Column(children: [
              Expanded(child: InAppWebView(
                initialUrlRequest: URLRequest(url: WebUri('https://$host/')),
                initialSettings: InAppWebViewSettings(userAgent: userAgent),
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
