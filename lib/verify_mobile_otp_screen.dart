import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'personal_information_screen.dart';
import 'state/registration_draft.dart';
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

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (seconds == 0) return;
      setState(() => seconds -= 1);
    });
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

  void _verify() {
    if (code.length != 6) {
      setState(() => error = 'Enter the 6-digit OTP.');
      return;
    }
    registrationDraft.phoneVerified = true;
    Navigator.push(context, evuddyRoute(const PersonalInformationScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final phone = registrationDraft.phoneDisplay;
    return AuthScreen(
      title: 'Enter the code',
      subtitle: 'Sent to ${phone.isEmpty ? "your number" : phone}. Any 6 digits work while SMS is in preview.',
      step: 1,
      error: error,
      footer: Row(
        children: [
          Expanded(
            child: EvuddyGhostButton(
              label: seconds == 0 ? 'Resend' : '00:${seconds.toString().padLeft(2, '0')}',
              onPressed: seconds == 0 ? () => setState(() => seconds = 45) : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: EvuddyButton(label: 'Verify', onPressed: _verify),
          ),
        ],
      ),
      children: [
        OtpRow(controllers: boxes, foci: foci),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Text(
            'Wrong number? Change',
            style: GoogleFonts.inter(
              color: Evuddy.green,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
