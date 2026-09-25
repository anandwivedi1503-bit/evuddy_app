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

  /// WebView OTP stores a token; native Auth may be empty. Refresh when JWT is stale.
  static Future<String?> freshIdToken({
    String? storedToken,
    String? refreshToken,
    bool force = false,
  }) async {
    await ensure();
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        return await user.getIdToken(force);
      }
    } catch (e) {
      debugPrint('Native token: $e');
    }
    if (refreshToken != null &&
        refreshToken.isNotEmpty &&
        (force || storedToken == null || storedToken.isEmpty || _jwtExpired(storedToken))) {
      final refreshed = await _refreshWithGoogle(refreshToken);
      if (refreshed != null) return refreshed;
    }
    if (storedToken != null && storedToken.isNotEmpty && !_jwtExpired(storedToken)) {
      return storedToken;
    }
    return storedToken;
  }

  static Future<String?> _refreshWithGoogle(String refreshToken) async {
    try {
      final r = await http
          .post(
            Uri.parse(
              'https://securetoken.googleapis.com/v1/token?key=${options.apiKey}',
            ),
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: 'grant_type=refresh_token&refresh_token=${Uri.encodeComponent(refreshToken)}',
          )
          .timeout(const Duration(seconds: 15));
      final j = jsonDecode(r.body);
      if (j is Map && j['id_token'] != null) {
        return j['id_token'].toString();
      }
    } catch (e) {
      debugPrint('Token refresh: $e');
    }
    return null;
  }

  static bool _jwtExpired(String token) {
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
      return now >= exp - 90;
    } catch (_) {
      return true;
    }
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
