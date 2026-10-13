import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Same Firebase project the website uses (`kebuone-otp`). Public web config.
class EvuddyFirebase {
  static const options = FirebaseOptions(
    apiKey: 'AIzaSyBlwZI_QVvI3mnEs1sgtIS_YQvpp5rU8Gk',
    appId: '1:548462513436:web:21cbd32f00c8a892a93ed9',
    messagingSenderId: '548462513436',
    projectId: 'kebuone-otp',
    authDomain: 'kebuone-otp.firebaseapp.com',
    storageBucket: 'kebuone-otp.firebasestorage.app',
  );

  static Future<void> ensure() async {
    try {
      if (Firebase.apps.isNotEmpty) return;
      await Firebase.initializeApp(options: options);
    } catch (e) {
      debugPrint('Firebase init: $e');
    }
  }

  static Future<void> sendOtp({
    required String phone10,
    required void Function(String verificationId) onCodeSent,
    required void Function(String message) onError,
    void Function()? onAutoVerified,
  }) async {
    await ensure();
    if (Firebase.apps.isEmpty) {
      onError('SMS could not start. Open this app on Android or iPhone — same Firebase OTP as evuddy.com.');
      return;
    }
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: '+91$phone10',
      timeout: const Duration(seconds: 60),
      verificationCompleted: (cred) async {
        await FirebaseAuth.instance.signInWithCredential(cred);
        onAutoVerified?.call();
      },
      verificationFailed: (e) {
        onError(_map(e));
      },
      codeSent: (id, _) => onCodeSent(id),
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  /// Last refresh_token returned by Google (WebView OTP has no native user).
  static String? lastRefreshToken;

  /// WebView OTP stores a token; native Auth may be empty. Always refresh when
  /// paying or starting a ride — same as evuddy.com `getIdToken(true)`.
  static Future<String?> freshIdToken({
    String? storedToken,
    String? refreshToken,
    String? expectedUid,
    bool force = false,
  }) async {
    await ensure();
    final storedOk =
        storedToken != null && storedToken.isNotEmpty && !jwtExpired(storedToken);
    final needRefresh = force || !storedOk;

    // Prefer Google refresh of the WebView session. Native Auth can be empty
    // or a leftover UID that does not own the rider on evuddy.com.
    if (needRefresh && refreshToken != null && refreshToken.isNotEmpty) {
      final refreshed = await _refreshWithGoogle(refreshToken);
      if (refreshed != null) return refreshed;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      final uidOk = expectedUid == null ||
          expectedUid.isEmpty ||
          user?.uid == expectedUid;
      if (user != null && uidOk) {
        final token = await user.getIdToken(force || !storedOk);
        final nativeRefresh = user.refreshToken;
        if (nativeRefresh != null && nativeRefresh.isNotEmpty) {
          lastRefreshToken = nativeRefresh;
        }
        if (token != null && token.isNotEmpty && !jwtExpired(token)) return token;
      }
    } catch (e) {
      debugPrint('Native token: $e');
    }

    if (storedOk) {
      if (refreshToken != null && refreshToken.isNotEmpty) {
        lastRefreshToken ??= refreshToken;
      }
      return storedToken;
    }

    if (refreshToken != null && refreshToken.isNotEmpty) {
      final refreshed = await _refreshWithGoogle(refreshToken);
      if (refreshed != null) return refreshed;
    }
    return null;
  }

  static Future<String?> _refreshWithGoogle(String refreshToken) async {
    try {
      final r = await http
          .post(
            Uri.parse(
              'https://securetoken.googleapis.com/v1/token?key=${options.apiKey}',
            ),
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body:
                'grant_type=refresh_token&refresh_token=${Uri.encodeComponent(refreshToken)}',
          )
          .timeout(const Duration(seconds: 15));
      final j = jsonDecode(r.body);
      if (j is Map && j['id_token'] != null) {
        final nextRefresh = j['refresh_token']?.toString();
        if (nextRefresh != null && nextRefresh.isNotEmpty) {
          lastRefreshToken = nextRefresh;
        }
        final id = j['id_token'].toString();
        if (id.isNotEmpty && !jwtExpired(id)) return id;
      }
    } catch (e) {
      debugPrint('Token refresh: $e');
    }
    return null;
  }

  static bool jwtExpired(String token) {
    final parts = token.split('.');
    if (parts.length < 2) return true;
    try {
      var payload = parts[1].replaceAll('-', '+').replaceAll('_', '/');
      while (payload.length % 4 != 0) {
        payload += '=';
      }
      final map = jsonDecode(utf8.decode(base64.decode(payload)));
      if (map is! Map || map['exp'] is! num) return true;
      final exp = (map['exp'] as num).toInt();
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      return now >= exp - 90; // match website: refresh before the hour is up
    } catch (_) {
      return true;
    }
  }

  static Future<void> signOut() async {
    await ensure();
    if (Firebase.apps.isEmpty) return;
    await FirebaseAuth.instance.signOut();
  }

  static Future<User> confirmOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    final cred = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    final res = await FirebaseAuth.instance.signInWithCredential(cred);
    final user = res.user;
    if (user == null) {
      throw FirebaseAuthException(code: 'null-user', message: 'Sign-in failed.');
    }
    return user;
  }

  static String _map(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number':
        return 'That mobile number is not valid.';
      case 'too-many-requests':
        return 'Too many OTP attempts. Wait a minute, then resend.';
      case 'quota-exceeded':
        return 'SMS quota reached. Try again later.';
      case 'missing-client-identifier':
      case 'app-not-authorized':
      case 'captcha-check-failed':
        return 'This phone build is not yet on the kebuone-otp Firebase app (SHA-1). SMS still works in the website; Android/iOS need that fingerprint added in Firebase — the website code is unchanged.';
      default:
        return e.message ?? 'Could not send OTP.';
    }
  }
}
