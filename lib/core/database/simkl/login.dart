import 'dart:async';
import 'dart:convert';

import 'package:animestream/core/app/env.dart';
import 'package:animestream/core/commons/enums.dart';
import 'package:animestream/core/data/secureStorage.dart';
import 'package:animestream/core/database/anilist/types.dart';
import 'package:animestream/core/database/database.dart';
import 'package:animestream/core/database/simkl/mutations.dart';
import 'package:animestream/core/database/simkl/types.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:animestream/core/network/network.dart';

class SimklLogin extends DatabaseLogin {
  static const callbackScheme = "auth.animestream://";

  @override
  Future<bool> initiateLogin() async {
    final clientId = AnimeStreamEnvironment.simklClientId;
    final clientSecret = AnimeStreamEnvironment.simklClientSecret;
    if (clientSecret.isEmpty || clientId.isEmpty) {
      throw Exception("Error: SIMKL CLIENT ID OR SECRET NOT PROVIDED!");
    }
    final authUrl = Uri.https("simkl.com", "/oauth/authorize", {
      'client_id': clientId,
      'response_type': "code",
      'redirect_uri': callbackScheme,
    });
    final res = await FlutterWebAuth2.authenticate(
        url: authUrl.toString(),
        callbackUrlScheme: callbackScheme.split(":")[0]);
    final code = Uri.parse(res).queryParameters['code'];
    if (code == null) {
      throw Exception("ERR_RECIEVED_AUTH_CODE_NULL");
    }
    final reqBody = jsonEncode({
      'code': code,
      'client_id': clientId,
      'client_secret': clientSecret,
      'redirect_uri': callbackScheme,
      'grant_type': "authorization_code"
    });
    final atres = await post(Uri.parse("https://api.simkl.com/oauth/token"),
        body: reqBody, headers: {'Content-Type': "application/json"});
    final json = jsonDecode(atres.body);
    final at = json['access_token'];

    if (at.isEmpty) throw Exception("ACCESS TOKEN IS NULL!");

    storeSecureVal(SecureStorageKey.simklToken, at);

    print("[SIMKL-LOGIN]: Login success, Access token saved!");
    return true;
  }

  @override
  Future<void> removeToken() async {
    final storage = FlutterSecureStorage();
    storage.delete(key: SecureStorageKey.simklToken.value);
  }

  static Future<PCKECodeResult> getPkceCode() async {
    final url =
        "https://api.simkl.com/oauth/pin?client_id=${AnimeStreamEnvironment.simklClientId}";
    final res = await get(Uri.parse(url));
    if (res.statusCode != 200)
      throw new Exception("Couldnt Get Code for Login");
    final jsoned = jsonDecode(res.body);
    final expSeconds = Duration(seconds: int.parse(jsoned['expires_in']));
    final currentUtcTime = DateTime.now().toUtc();
    final codeData = PCKECodeResult(
      userCode: jsoned['user_code'],
      verificationUrl: jsoned['verification_url'],
      deviceCode: jsoned['device_code'],
      expiry: currentUtcTime.add(expSeconds),
      interval: jsoned['interval'],
    );
    return codeData;
  }

  //function to call for polling
  static Future<bool> verifyPkceCode(PCKECodeResult codeRes) async {
    final url =
        "https://api.simkl.com/oauth/pin/${codeRes.userCode}?client_id=${AnimeStreamEnvironment.simklClientId}";
    final Completer<bool> completer = Completer<bool>();
    int failCount = 0;
    Timer.periodic(Duration(seconds: codeRes.interval), (timer) async {
      //kill after 5 failed request attempts
      if (failCount > 5) {
        timer.cancel();
        completer.complete(false);
      } else if (DateTime.now().isAfter(codeRes.expiry)) {
        timer.cancel();
        completer.completeError(Exception("CODE_EXPIRED"));
      } else {
        try {
          final res = await get(Uri.parse(url));
          final jsoned = jsonDecode(res.body);

          //stop the timer and save the token
          if (jsoned['result'] == "OK") {
            storeSecureVal(SecureStorageKey.simklToken, jsoned['access_token']);
            print("[SIMKL-LOGIN]: Login success, Access token saved!");
            timer.cancel();
            completer.complete(true);
          }
        } catch (err) {
          print(err);
          failCount++;
        }
      }
    });
    return await completer.future;
  }

  static Future<SimklDeviceCodeResult> requestDeviceCode() async {
    final clientId = AnimeStreamEnvironment.simklClientId;
    if (clientId.isEmpty) {
      throw Exception("SIMKL_CLIENT_ID is missing from this build");
    }

    final res = await post(
      Uri.parse("https://api.simkl.com/oauth2/device"),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {'client_id': clientId},
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception("SIMKL_DEVICE_CODE_FAILED_${res.statusCode}: ${res.body}");
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final deviceCode = data['device_code']?.toString() ?? '';
    final userCode = data['user_code']?.toString() ?? '';

    if (deviceCode.isEmpty || userCode.isEmpty) {
      throw Exception("SIMKL_DEVICE_CODE_RESPONSE_INVALID");
    }

    return SimklDeviceCodeResult(
      deviceCode: deviceCode,
      userCode: userCode,
      verificationUri:
          data['verification_uri']?.toString() ?? 'https://simkl.com/pin',
      verificationUriComplete: data['verification_uri_complete']?.toString(),
      expiresAt: DateTime.now().toUtc().add(
            Duration(
              seconds: int.tryParse(data['expires_in'].toString()) ?? 900,
            ),
          ),
      intervalSeconds: int.tryParse(data['interval'].toString()) ?? 5,
    );
  }

  static Future<bool> pollDeviceCode(
    SimklDeviceCodeResult code, {
    bool Function()? shouldCancel,
  }) async {
    final clientId = AnimeStreamEnvironment.simklClientId;
    if (clientId.isEmpty) {
      throw SimklDeviceAuthException(
        'missing_client_id',
        'SIMKL Client ID is missing from this build.',
      );
    }

    var interval = code.intervalSeconds;

    while (DateTime.now().toUtc().isBefore(code.expiresAt)) {
      if (shouldCancel?.call() ?? false) {
        throw SimklDeviceAuthException('cancelled', 'Login cancelled.');
      }

      await Future.delayed(Duration(seconds: interval));

      if (shouldCancel?.call() ?? false) {
        throw SimklDeviceAuthException('cancelled', 'Login cancelled.');
      }

      final res = await post(
        Uri.parse("https://api.simkl.com/oauth2/token"),
        headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
        body: {
          'grant_type': 'urn:ietf:params:oauth:grant-type:device_code',
          'device_code': code.deviceCode,
          'client_id': clientId,
        },
      );

      Map<String, dynamic> data = {};
      if (res.body.isNotEmpty) {
        final decoded = jsonDecode(res.body);
        if (decoded is Map<String, dynamic>) {
          data = decoded;
        }
      }

      final token = data['access_token']?.toString();
      if (res.statusCode >= 200 &&
          res.statusCode < 300 &&
          token != null &&
          token.isNotEmpty) {
        await _validateAccessToken(token);
        await storeSecureVal(SecureStorageKey.simklToken, token);
        print("[SIMKL-LOGIN]: Device login success, Access token validated and saved!");
        return true;
      }

      final error = data['error']?.toString() ?? '';

      if (error == 'authorization_pending') {
        continue;
      }

      if (error == 'slow_down') {
        interval += 5;
        continue;
      }

      if (error == 'expired_token') {
        throw SimklDeviceAuthException(
          'expired_token',
          'The SIMKL code expired. Requesting a new code…',
        );
      }

      if (error == 'access_denied') {
        throw SimklDeviceAuthException(
          'access_denied',
          'SIMKL authorization was denied.',
        );
      }

      throw SimklDeviceAuthException(
        error.isEmpty ? 'token_error' : error,
        'SIMKL login failed (${res.statusCode}).',
      );
    }

    throw SimklDeviceAuthException(
      'expired_token',
      'The SIMKL code expired. Requesting a new code…',
    );
  }

  static Future<void> _validateAccessToken(String token) async {
    final clientId = AnimeStreamEnvironment.simklClientId;
    final res = await post(
      Uri.parse("https://api.simkl.com/users/settings"),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'simkl-api-key': clientId,
      },
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw SimklDeviceAuthException(
        'invalid_token',
        'SIMKL returned ${res.statusCode} while validating the login.',
      );
    }
  }

  Future<UserModal> getUserProfile() async {
    final url = "https://api.simkl.com/users/settings";
    final headers = await SimklMutation.getHeader();
    final res = await post(Uri.parse(url), headers: headers);

    if (res.statusCode == 401) {
      throw SimklException("Unauthorized - Invalid Token", 401);
    }

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw SimklException(
          "Failed to fetch simkl user profile", res.statusCode);
    }

    final jsoned = jsonDecode(res.body) as Map<String, dynamic>;
    final user = (jsoned['user'] is Map<String, dynamic>)
        ? jsoned['user'] as Map<String, dynamic>
        : <String, dynamic>{};
    final account = (jsoned['account'] is Map<String, dynamic>)
        ? jsoned['account'] as Map<String, dynamic>
        : <String, dynamic>{};
    final ids = (user['ids'] is Map<String, dynamic>)
        ? user['ids'] as Map<String, dynamic>
        : <String, dynamic>{};

    final rawId = account['id'] ?? ids['simkl'] ?? jsoned['id'];
    final parsedId = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '');
    if (parsedId == null) {
      throw SimklException("SIMKL profile did not include a usable user id", 500);
    }

    return UserModal(
      avatar: user['avatar']?.toString(),
      banner: null,
      id: parsedId,
      name: user['name']?.toString() ?? 'SIMKL',
    );
  }

  static Future<bool> isLoggedIn() async {
    final token = await getSecureVal(SecureStorageKey.simklToken);
    if (token == null || token.isEmpty) {
      return false;
    }
    return true;
  }

  @override
  Future<void>? refreshToken() {
    return null; //permanent access token, no need to refresh
  }
}

class SimklDeviceAuthException implements Exception {
  final String code;
  final String message;

  const SimklDeviceAuthException(this.code, this.message);

  @override
  String toString() => message;
}

class SimklDeviceCodeResult {
  final String deviceCode;
  final String userCode;
  final String verificationUri;
  final String? verificationUriComplete;
  final DateTime expiresAt;
  final int intervalSeconds;

  const SimklDeviceCodeResult({
    required this.deviceCode,
    required this.userCode,
    required this.verificationUri,
    required this.verificationUriComplete,
    required this.expiresAt,
    required this.intervalSeconds,
  });
}

class PCKECodeResult {
  final String userCode;
  final String verificationUrl;
  final String deviceCode;
  final DateTime expiry;
  final int interval;

  PCKECodeResult({
    required this.userCode,
    required this.verificationUrl,
    required this.deviceCode,
    required this.expiry,
    required this.interval,
  });
}
