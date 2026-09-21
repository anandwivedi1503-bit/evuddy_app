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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
          child: Column(
            children: [
              const EvuddyHeader(showBack: false),
              const Spacer(),
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Evuddy.logoGreen, Evuddy.logoPink],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Evuddy.magenta.withOpacity(0.25),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(Icons.check_rounded, size: 40, color: Colors.white),
              ),
              const SizedBox(height: 28),
              Text(
                first.isEmpty ? 'You’re in.' : 'You’re in,\n$first.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 12),
              const Text(
                'KYC sits with ops before Book EV — same rule as the website. Nothing was sent to the server in this step.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                d.phoneDisplay,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  color: Evuddy.green,
                  letterSpacing: 0.4,
                ),
              ),
              const Spacer(),
              EvuddyButton(
                label: 'Back to mobile',
                icon: Icons.arrow_back_rounded,
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
