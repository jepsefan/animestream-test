import 'package:animestream/core/app/values.dart';
import 'package:animestream/core/network/network.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Sessions are stored only for explicitly supported domains.
/// Never log cookies, web tokens, or complete response bodies.
class SourceVerificationSession {
  SourceVerificationSession._();
  static final instance = SourceVerificationSession._();
  static const _storage = FlutterSecureStorage();
  static const host = 'animepahe.pw';
  static const _key = 'source_verify_animepahe_cookie_v1';
  String? _cookie;

  Future<void> saveCookies(Map<String, String> cookies) async {
    final allowed = cookies.entries.where((e) =>
      e.key.isNotEmpty && e.value.isNotEmpty &&
      !e.key.contains(';') && !e.value.contains(';')).toList();
    if (allowed.isEmpty) return;
    _cookie = allowed.map((e) => '${e.key}=${e.value}').join('; ');
    await _storage.write(key: _key, value: _cookie);
  }

  Future<String?> cookieFor(Uri uri) async {
    if (uri.scheme != 'https' || uri.host.toLowerCase() != host) return null;
    return _cookie ??= await _storage.read(key: _key);
  }

  Future<void> clear() async {
    _cookie = null;
    await _storage.delete(key: _key);
  }

  /// Positive result requires the source's JSON API, not a challenge HTML page.
  Future<bool> probe() async {
    try {
      final uri = Uri.https(host, '/api', {'m': 'search', 'q': 'naruto'});
      final cookie = await cookieFor(uri);
      if (cookie == null || cookie.isEmpty) return false;
      final res = await http.get(uri, headers: {
        'Cookie': cookie,
        'Referer': 'https://$host/',
        'User-Agent': AppValues.defaultClientUserAgent,
      }, cacheDuration: Duration.zero);
      if (res.statusCode != 200) return false;
      final data = res.json;
      return data is Map && data['data'] is List;
    } catch (_) {
      return false;
    }
  }
}
