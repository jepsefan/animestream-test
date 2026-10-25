import 'package:animestream/core/anime/providers/aniyomiExtensionBridge.dart';
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

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    if (widget.extensionPackage != null) {
      try {
        final data = await AniyomiExtensionBridge.extensionVerificationInfo(
            widget.extensionPackage!);
        final proposed = data['host']?.toString().toLowerCase() ?? '';
        if (RegExp(r'^(?:[a-z0-9-]+\.)?animepahe\.[a-z]{2,12}$').hasMatch(proposed)) {
          host = proposed;
        }
        final ua = data['userAgent']?.toString() ?? '';
        if (ua.isNotEmpty) userAgent = ua;
      } catch (_) {
        // Fall back to a known public source host. Never expose bridge errors.
      }
    }
    if (mounted) setState(() => initialized = true);
  }

  String _diagnosis(Map<String, dynamic> data) {
    final diagnostics = (data['networkDiagnostics'] as List?) ?? const [];
    final parts = <String>[];
    for (final item in diagnostics.whereType<Map>()) {
      final hostName = item['host']?.toString() ?? '';
      if (!RegExp(r'^(?:[a-z0-9-]+\.)?animepahe\.[a-z]{2,12}$').hasMatch(hostName)) continue;
      final status = item['status']?.toString() ?? 'unknown';
      if (status == '403' || status == '503' || status == '429' ||
          status == 'network_error' || status == '200') {
        parts.add('$hostName: HTTP $status');
      }
    }
    return parts.isEmpty ? 'Extension search: ${data['status'] ?? 'unknown'}'
        : parts.toSet().join(' • ');
  }

  Future<void> _check() async {
    if (checking || finished || !initialized) return;
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
        final status = result['status']?.toString();
        final count = (result['resultCount'] as num?)?.toInt() ??
            ((result['results'] as List?)?.length ?? 0);
        accepted = (status == 'search_completed' ||
            status == 'search_completed_unverified') && count > 0 &&
            result['resultRelevance'] != 'unverified_unrelated_catalogue';
        diagnostic = _diagnosis(result);
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
            '$diagnostic. The selected source is still unavailable. Verify in the browser and try again.');
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
      appBar: AppBar(title: const Text('Verify AnimePahe')),
      body: !initialized
          ? const Center(child: CircularProgressIndicator())
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
