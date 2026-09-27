import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:animestream/core/app/env.dart';

class AniListLocalTvLoginSession {
  AniListLocalTvLoginSession._({
    required this.server,
    required this.localIp,
    required this.sessionId,
  });

  final HttpServer server;
  final String localIp;
  final String sessionId;
  final Completer<String> _tokenCompleter = Completer<String>();

  bool _closed = false;

  int get port => server.port;

  String get localUrl => 'http://$localIp:$port/login/$sessionId';

  Future<String> get token => _tokenCompleter.future;

  static Future<AniListLocalTvLoginSession> start() async {
    final clientId = AnimeStreamEnvironment.anilistPinClientId;
    if (clientId.isEmpty) {
      throw Exception('ANILIST_PIN_CLIENT_ID is missing from this build');
    }

    final ip = await _findLocalIpv4();
    if (ip == null) {
      throw Exception('Could not find a local IPv4 address');
    }

    final server = await HttpServer.bind(
      InternetAddress.anyIPv4,
      0,
      shared: false,
    );

    final session = AniListLocalTvLoginSession._(
      server: server,
      localIp: ip,
      sessionId: _newSessionId(),
    );

    unawaited(session._serve());
    return session;
  }

  static String _newSessionId() {
    final random = Random.secure();
    final bytes = List<int>.generate(24, (_) => random.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  static Future<String?> _findLocalIpv4() async {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLoopback: false,
      includeLinkLocal: false,
    );

    String? fallback;
    for (final interface in interfaces) {
      for (final address in interface.addresses) {
        final ip = address.address;
        fallback ??= ip;
        if (_isPrivateIpv4(ip)) return ip;
      }
    }
    return fallback;
  }

  static bool _isPrivateIpv4(String ip) {
    final parts = ip.split('.').map(int.tryParse).toList();
    if (parts.length != 4 || parts.any((part) => part == null)) return false;
    final a = parts[0]!;
    final b = parts[1]!;
    return a == 10 ||
        (a == 172 && b >= 16 && b <= 31) ||
        (a == 192 && b == 168);
  }

  Future<void> _serve() async {
    try {
      await for (final request in server) {
        await _handleRequest(request);
      }
    } catch (_) {
      // Closing the server while waiting for login ends this loop normally.
    }
  }

  Future<void> _handleRequest(HttpRequest request) async {
    request.response.headers
      ..set(HttpHeaders.cacheControlHeader, 'no-store')
      ..set('X-Content-Type-Options', 'nosniff')
      ..set('Referrer-Policy', 'no-referrer');

    final loginPath = '/login/$sessionId';
    final tokenPath = '/token/$sessionId';

    if (request.method == 'GET' && request.uri.path == loginPath) {
      request.response.headers.contentType =
          ContentType('text', 'html', charset: 'utf-8');
      request.response.write(_loginPage());
      await request.response.close();
      return;
    }

    if (request.method == 'POST' && request.uri.path == tokenPath) {
      final body = await utf8.decoder.bind(request).join();
      final form = Uri.splitQueryString(body);
      final token = (form['token'] ?? '').trim();

      if (token.isEmpty || token.length > 8192) {
        request.response.statusCode = HttpStatus.badRequest;
        request.response.headers.contentType =
            ContentType('text', 'html', charset: 'utf-8');
        request.response.write(_resultPage(
          'Invalid token',
          'No valid token was received. Go back and try again.',
        ));
        await request.response.close();
        return;
      }

      if (!_tokenCompleter.isCompleted) {
        _tokenCompleter.complete(token);
      }

      request.response.headers.contentType =
          ContentType('text', 'html', charset: 'utf-8');
      request.response.write(_resultPage(
        'Token sent to TV',
        'You can return to AnimeStream on the TV.',
      ));
      await request.response.close();
      return;
    }

    request.response.statusCode = HttpStatus.notFound;
    await request.response.close();
  }

  String _loginPage() {
    final clientId = AnimeStreamEnvironment.anilistPinClientId;
    final authorize = Uri.https(
      'anilist.co',
      '/api/v2/oauth/authorize',
      {
        'client_id': clientId,
        'response_type': 'token',
      },
    ).toString();

    return '''<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>AnimeStream AniList Login</title>
<style>
body{font-family:system-ui,sans-serif;background:#111;color:#eee;margin:0;padding:24px}
main{max-width:560px;margin:auto}
a,button{display:block;width:100%;box-sizing:border-box;padding:14px;margin:14px 0;border:0;border-radius:10px;font-size:17px;text-align:center}
a{background:#3db4f2;color:#081018;text-decoration:none;font-weight:700}
button{background:#eee;color:#111;font-weight:700}
textarea{width:100%;box-sizing:border-box;min-height:150px;padding:12px;border-radius:10px;font-size:15px}
small{color:#aaa}
</style>
</head>
<body>
<main>
<h1>Connect AniList to AnimeStream TV</h1>
<p>1. Open AniList and approve AnimeStream. AniList will show an access token.</p>
<a href="$authorize" target="_blank" rel="noreferrer">Open AniList login</a>
<p>2. Copy the token AniList shows, return to this page, and paste it below.</p>
<form method="post" action="/token/$sessionId">
<textarea name="token" autocomplete="off" autocapitalize="off" spellcheck="false" required></textarea>
<button type="submit">Send token to TV</button>
</form>
<small>The token is sent only to the local IP address of your TV over your current LAN. Keep this page private.</small>
</main>
</body>
</html>''';
  }

  String _resultPage(String title, String message) {
    return '''<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>$title</title>
<style>
body{font-family:system-ui,sans-serif;background:#111;color:#eee;margin:0;padding:24px}
main{max-width:560px;margin:auto;text-align:center}
</style>
</head>
<body><main><h1>$title</h1><p>$message</p></main></body>
</html>''';
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await server.close(force: true);
  }
}
