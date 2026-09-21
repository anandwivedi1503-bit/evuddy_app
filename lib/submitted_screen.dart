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
    final status = d.approvalStatus.isEmpty ? 'Under Review' : d.approvalStatus;
    final title = d.bookingEnabled && status == 'Approved'
        ? (first.isEmpty ? 'You’re approved.' : 'You’re approved, $first.')
        : (first.isEmpty ? 'You’re in.' : 'You’re in, $first.');
    return AuthScreen(
      showBack: false,
      kicker: 'Application',
      title: title,
      subtitle: d.bookingEnabled
          ? 'Book EV is unlocked on this number — same rule as the website.'
          : 'KYC sits with ops before Book EV opens. Status: $status.',
      footer: EvuddyButton(
        label: 'Back to start',
        icon: Icons.arrow_back_rounded,
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
          child: Icon(
            d.bookingEnabled ? Icons.verified_rounded : Icons.hourglass_top_rounded,
            size: 36,
            color: Evuddy.green,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          d.phoneDisplay,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: Evuddy.ink,
          ),
        ),
        if (d.riderId != null) ...[
          const SizedBox(height: 8),
          Text(
            'Rider ID ${d.riderId}',
            style: GoogleFonts.plusJakartaSans(color: Evuddy.muted, fontSize: 13),
          ),
        ],
      ],
    );
  }
}
