import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'kyc_details_screen.dart';
import 'state/registration_draft.dart';
import 'theme/evuddy.dart';
import 'widgets/chrome.dart';

class RegistrationOtpScreen extends StatelessWidget {
  const RegistrationOtpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final d = registrationDraft;
    return AuthScreen(
      kicker: 'Phone verified',
      title: 'Number verified',
      subtitle: 'Same as the website: one Firebase SMS, then KYC.',
      step: 2,
      footer: EvuddyButton(
        label: 'Continue to KYC',
        onPressed: () {
          Navigator.push(context, evuddyRoute(const KycDetailsScreen()));
        },
      ),
      children: [
        SurfaceCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'VERIFIED NUMBER',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w800,
                  color: Evuddy.greenDeep,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                d.phoneDisplay,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                d.fullName.isEmpty ? 'Rider' : d.fullName,
                style: GoogleFonts.plusJakartaSans(color: Evuddy.muted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
