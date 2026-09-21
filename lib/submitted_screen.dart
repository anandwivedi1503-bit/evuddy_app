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
      title: first.isEmpty ? 'You’re in.' : 'You’re in, $first.',
      subtitle: 'Ops will review KYC before Book EV opens. Nothing was sent to the server yet.',
      footer: EvuddyButton(
        label: 'Done',
        icon: Icons.check_rounded,
        onPressed: () {
          Navigator.of(context).pushAndRemoveUntil(
            evuddyRoute(const LoginScreen()),
            (route) => false,
          );
        },
      ),
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: const BoxDecoration(
            color: Evuddy.greenSoft,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_rounded, size: 36, color: Evuddy.green),
        ),
        const SizedBox(height: 16),
        Text(
          d.phoneDisplay,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: Evuddy.ink,
          ),
        ),
      ],
    );
  }
}
