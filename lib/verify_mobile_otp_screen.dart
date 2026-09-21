import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'api/evuddy_api.dart';
import 'api/firebase_phone.dart';
import 'kyc_details_screen.dart';
import 'state/registration_draft.dart';
import 'submitted_screen.dart';
import 'theme/evuddy.dart';
import 'widgets/chrome.dart';

class VerifyMobileOtpScreen extends StatefulWidget {
  const VerifyMobileOtpScreen({super.key});

  @override
  State<VerifyMobileOtpScreen> createState() => _VerifyMobileOtpScreenState();
}

class _VerifyMobileOtpScreenState extends State<VerifyMobileOtpScreen> {
  final boxes = List.generate(6, (_) => TextEditingController());
  final foci = List.generate(6, (_) => FocusNode());
  int seconds = 45;
  Timer? timer;
  String? error;
  bool sending = true;
  bool verifying = false;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (seconds == 0) return;
      setState(() => seconds -= 1);
    });
    _send();
  }

  @override
  void dispose() {
    timer?.cancel();
    for (final c in boxes) {
      c.dispose();
    }
    for (final f in foci) {
      f.dispose();
    }
    super.dispose();
  }

  String get code => boxes.map((c) => c.text).join();

  Future<void> _send() async {
    setState(() {
      sending = true;
      error = null;
      seconds = 45;
    });
    await EvuddyFirebase.sendOtp(
      phone10: registrationDraft.phone,
      onCodeSent: (id) {
        if (!mounted) return;
        registrationDraft.verificationId = id;
        setState(() => sending = false);
      },
      onError: (m) {
        if (!mounted) return;
        setState(() {
          sending = false;
          error = m;
        });
      },
      onAutoVerified: () {
        if (!mounted) return;
        _afterFirebaseUser();
      },
    );
  }

  Future<void> _verify() async {
    if (code.length != 6) {
      setState(() => error = 'Enter the 6-digit OTP.');
      return;
    }
    final id = registrationDraft.verificationId;
    if (id == null) {
      setState(() => error = 'Request a new OTP first.');
      return;
    }
    setState(() {
      verifying = true;
      error = null;
    });
    try {
      await EvuddyFirebase.confirmOtp(verificationId: id, smsCode: code);
      await _afterFirebaseUser();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        verifying = false;
        error = e.code == 'invalid-verification-code'
            ? 'Invalid OTP. Check the SMS and try again.'
            : (e.message ?? 'OTP failed.');
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        verifying = false;
        error = e.toString();
      });
    }
  }

  Future<void> _afterFirebaseUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        verifying = false;
        error = 'Phone sign-in did not complete.';
      });
      return;
    }
    final token = await user.getIdToken(true);
    if (token == null || token.isEmpty) {
      setState(() {
        verifying = false;
        error = 'Could not read the Firebase session. Resend OTP.';
      });
      return;
    }
    registrationDraft
      ..phoneVerified = true
      ..firebaseUid = user.uid
      ..firebaseIdToken = token;

    try {
      final lookup = await EvuddyApi.lookupRider(
        phone: registrationDraft.phone,
        idToken: token,
      );
      if (!mounted) return;
      if (lookup.found) {
        registrationDraft
          ..riderId = lookup.riderId
          ..approvalStatus = lookup.approvalStatus
          ..bookingEnabled = lookup.bookingEnabled;
        if (lookup.approvalStatus == 'Rejected') {
          setState(() {
            verifying = false;
            error = 'This number was rejected. Contact EVUDDY support.';
          });
          return;
        }
        Navigator.pushReplacement(context, evuddyRoute(const SubmittedScreen()));
        return;
      }
    } catch (_) {
      // New riders 404 — continue to KYC.
    }
    if (!mounted) return;
    Navigator.pushReplacement(context, evuddyRoute(const KycDetailsScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final phone = registrationDraft.phoneDisplay;
    return AuthScreen(
      kicker: 'OTP  ·  Step 2 of 4',
      title: 'OTP Verification',
      subtitle: 'Firebase SMS to ${phone.isEmpty ? "your number" : phone} — the same check as the website.',
      step: 2,
      error: error,
      footer: Row(
        children: [
          Expanded(
            child: EvuddyGhostButton(
              label: seconds == 0 ? 'Resend' : '00:${seconds.toString().padLeft(2, '0')}',
              onPressed: seconds == 0 && !sending ? _send : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: EvuddyButton(
              label: 'Verify OTP',
              busy: verifying || sending,
              onPressed: verifying || sending ? null : _verify,
            ),
          ),
        ],
      ),
      children: [
        if (sending)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'Sending OTP…',
              style: GoogleFonts.plusJakartaSans(
                color: Evuddy.greenDeep,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        OtpRow(controllers: boxes, foci: foci),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Text(
            'Wrong number? Change',
            style: GoogleFonts.plusJakartaSans(
              color: Evuddy.green,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
