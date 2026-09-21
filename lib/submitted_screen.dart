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
    return AuthScreen(
      showBack: false,
      kicker: 'Application received',
      title: first.isEmpty ? 'You’re in.' : 'You’re in,\n$first.',
      subtitle:
          'KYC sits with ops before Book EV opens. Nothing was sent to the server in this step.',
      footer: EvuddyButton(
        label: 'Back to mobile',
        icon: Icons.arrow_back_rounded,
        onPressed: () {
          Navigator.of(context).pushAndRemoveUntil(
            evuddyRoute(const LoginScreen()),
            (route) => false,
          );
        },
      ),
      children: [
        Center(
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Evuddy.logoGreen, Evuddy.logoPink],
              ),
              boxShadow: [
                BoxShadow(
                  color: Evuddy.magenta.withOpacity(0.28),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: const Icon(Icons.check_rounded, size: 44, color: Colors.white),
          ),
        ),
        const SizedBox(height: 22),
        Center(
          child: Text(
            d.phoneDisplay,
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
              color: Evuddy.greenDeep,
              letterSpacing: 0.4,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }
}
