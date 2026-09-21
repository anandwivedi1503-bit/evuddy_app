import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'api/evuddy_api.dart';
import 'api/web_otp.dart';
import 'kyc_details_screen.dart';
import 'login_screen.dart';
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
  final webOtp = WebOtpController();
  int seconds = 45;
  Timer? timer;
  String? error;
  bool sending = false;
  bool verifying = false;
  bool sentOk = false;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (seconds == 0) return;
      setState(() => seconds -= 1);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _send());
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
      sentOk = false;
    });
    try {
      await webOtp.send(registrationDraft.phone);
      if (!mounted) return;
      setState(() {
        sending = false;
        sentOk = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        sending = false;
        error = e.toString();
      });
    }
  }

  Future<void> _verify() async {
    if (code.length != 6) {
      setState(() => error = 'Enter the 6-digit OTP.');
      return;
    }
    setState(() {
      verifying = true;
      error = null;
    });
    try {
      final session = await webOtp.confirm(code);
      registrationDraft
        ..phoneVerified = true
        ..firebaseUid = session.uid
        ..firebaseIdToken = session.token;
      await _routeAfterOtp();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        verifying = false;
        error = e.toString().contains('invalid')
            ? 'Invalid OTP. Check the SMS and try again.'
            : e.toString();
      });
    }
  }

  Future<void> _routeAfterOtp() async {
    final token = registrationDraft.firebaseIdToken;
    if (token == null) return;
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
        if (registrationDraft.canBook) {
          registrationDraft.shellTab = 1;
          riderSessionTick.value++;
          Navigator.of(context).popUntil((r) => r.isFirst);
          return;
        }
        Navigator.pushReplacement(context, evuddyRoute(const SubmittedScreen()));
        return;
      }
    } catch (_) {}
    if (!mounted) return;
    if (registrationDraft.fullName.isNotEmpty && registrationDraft.email.isNotEmpty) {
      Navigator.pushReplacement(context, evuddyRoute(const KycDetailsScreen()));
      return;
    }
    Navigator.pushReplacement(context, evuddyRoute(const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final phone = registrationDraft.phoneDisplay;
    return AuthScreen(
      kicker: 'OTP',
      title: 'OTP Verification',
      subtitle:
          'SMS to ${phone.isEmpty ? "your number" : phone}. If Google asks you to select cars or buses, use the large box below — it is the same recaptcha as evuddy.com.',
      error: error,
      expanded: WebOtpPanel(controller: webOtp),
      footer: Column(
        children: [
          OtpRow(controllers: boxes, foci: foci),
          const SizedBox(height: 12),
          Row(
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
        ],
      ),
      children: [
        Text(
          sending
              ? 'Sending OTP… complete the security check in the box below if asked.'
              : sentOk
                  ? 'OTP sent. Enter the 6 digits from SMS.'
                  : 'Preparing secure SMS…',
          style: GoogleFonts.plusJakartaSans(
            color: Evuddy.greenDeep,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Text(
            'Wrong number? Change',
            style: GoogleFonts.plusJakartaSans(
              color: Evuddy.green,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
