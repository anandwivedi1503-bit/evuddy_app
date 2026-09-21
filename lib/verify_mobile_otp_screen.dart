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
      kicker: 'Secure sign in',
      title: 'Enter your OTP',
      subtitle:
          'A 6-digit code is sent to your mobile. SMS is in preview — any 6 digits continue.',
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
        SurfaceCard(
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Evuddy.greenSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text('🇮🇳', style: TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CODE SENT TO',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        letterSpacing: 1.4,
                        fontWeight: FontWeight.w800,
                        color: Evuddy.muted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      phone.isEmpty ? '+91' : phone,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Change',
                  style: GoogleFonts.plusJakartaSans(
                    color: Evuddy.green,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('ENTER 6-DIGIT OTP', style: Theme.of(context).textTheme.labelSmall),
            Text(
              'Auto-read later',
              style: GoogleFonts.plusJakartaSans(
                color: Evuddy.green,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        OtpRow(controllers: boxes, foci: foci),
        const SizedBox(height: 16),
        InfoNote(
          text:
              'OTP will be sent to ${phone.isEmpty ? "your number" : phone} when the live network is connected.',
        ),
      ],
    );
  }
}
