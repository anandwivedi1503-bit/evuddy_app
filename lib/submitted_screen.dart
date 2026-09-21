import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'login_screen.dart';
import 'state/registration_draft.dart';
import 'theme/evuddy.dart';
import 'widgets/chrome.dart';

class SubmittedScreen extends StatelessWidget {
  const SubmittedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final d = registrationDraft;
    final first = d.fullName.split(' ').first;
    return Scaffold(
      backgroundColor: Evuddy.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 12, 28, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
              const Spacer(),
              Container(width: 28, height: 3, color: Evuddy.green),
              const SizedBox(height: 20),
              Text(
                first.isEmpty ? 'You’re in.' : 'You’re in,\n$first.',
                style: GoogleFonts.manrope(
                  fontSize: 40,
                  height: 1.05,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.4,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'KYC sits with ops before Book EV — same rule as the website. Nothing was sent to the server in this step.',
                style: GoogleFonts.manrope(
                  fontSize: 15,
                  height: 1.45,
                  color: const Color(0xFF9A9A9A),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                d.phoneDisplay,
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: Evuddy.green,
                ),
              ),
              const Spacer(),
              EvuddyButton(
                label: 'Back to mobile',
                icon: Icons.arrow_back_rounded,
                dark: false,
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    evuddyRoute(const LoginScreen()),
                    (route) => false,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
