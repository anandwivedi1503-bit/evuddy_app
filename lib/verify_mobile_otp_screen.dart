import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    webOtp.onReady = () {
      if (!mounted || sentOk || sending) return;
      _send();
    };
    webOtp.onCaptcha = () {
      if (!mounted) return;
      setState(() {});
    };
    webOtp.onExpired = () {
      if (!mounted) return;
      setState(() {
        sending = false;
        sentOk = false;
        error = 'Security check expired. Tap Retry.';
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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                    ),
                    Expanded(
                      child: Text(
                        sentOk ? 'Enter OTP' : 'Verify number',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: Evuddy.ink,
                            ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Text(
                        'Change',
                        style: GoogleFonts.plusJakartaSans(
                          color: Evuddy.green,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(
                  sentOk
                      ? 'SMS sent to ${phone.isEmpty ? "your number" : phone}.'
                      : 'Complete Google’s check if it appears below. We send SMS after it passes.',
                  style: GoogleFonts.plusJakartaSans(
                    color: Evuddy.muted,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Text(
                    error!,
                    style: GoogleFonts.plusJakartaSans(
                      color: Evuddy.danger,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              Expanded(
                child: WebOtpPanel(controller: webOtp),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: sentOk
                    ? Column(
                        children: [
                          OtpPinField(
                            controller: pin,
                            autofocus: true,
                            onCompleted: (_) => _verify(),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: EvuddyGhostButton(
                                  label: seconds == 0
                                      ? 'Resend'
                                      : '00:${seconds.toString().padLeft(2, '0')}',
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
                                ? 'If pictures appear, tap them. SMS sends after the check.'
                                : 'Loading security check…',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              color: Evuddy.muted,
                              fontSize: 12,
                            ),
                          ),
                          if (!sending && error != null) ...[
                            const SizedBox(height: 10),
                            EvuddyButton(
                              label: 'Retry security check',
                              onPressed: _send,
                            ),
                          ],
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
