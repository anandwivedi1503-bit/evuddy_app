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
  final pin = TextEditingController();
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
    webOtp.onAutofill = (code) {
      pin.text = code;
      _verify();
    };
    webOtp.onCaptcha = () {
      if (!mounted || sentOk || sending) return;
      _send();
    };
    webOtp.onExpired = () {
      if (!mounted) return;
      setState(() {
        sending = false;
        sentOk = false;
        error = 'Security check expired. Tick “I’m not a robot” again.';
        seconds = 0;
      });
    };
  }

  @override
  void dispose() {
    timer?.cancel();
    pin.dispose();
    super.dispose();
  }

  String get code => pin.text.replaceAll(RegExp(r'\D'), '');

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
        seconds = 0;
        error = e.toString();
      });
    }
  }

  Future<void> _verify() async {
    if (code.length != 6) {
      setState(() => error = 'Enter the 6-digit OTP, or wait for SMS autofill.');
      return;
    }
    if (verifying) return;
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
      title: sentOk ? 'OTP Verification' : 'Security check',
      subtitle: sentOk
          ? 'SMS to ${phone.isEmpty ? "your number" : phone}. We listen for the code and fill it.'
          : 'Tick I’m not a robot below. If Google shows pictures (cars, buses), complete them — then we send SMS.',
      error: error,
      expanded: WebOtpPanel(controller: webOtp),
      footer: sentOk
          ? Column(
              children: [
                OtpPinField(controller: pin, autofocus: true, onCompleted: (_) => _verify()),
                const SizedBox(height: 8),
                Text(
                  'Autofill from SMS when your phone offers it — we never read your full inbox.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(color: Evuddy.muted, fontSize: 11),
                ),
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
            )
          : Column(
              children: [
                Text(
                  sending
                      ? 'Security check passed — sending SMS…'
                      : 'Do not type an OTP yet. Finish the box first.',
                  textAlign: TextAlign.center,
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
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      color: Evuddy.green,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
      children: const [],
    );
  }
}
