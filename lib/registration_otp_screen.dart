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
      title: 'You’re confirmed',
      subtitle:
          'This step matches the website: one phone check, then KYC. No second SMS.',
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
              Row(
                children: [
                  const EvuddyBoltMark(size: 44),
                  const SizedBox(width: 12),
                  Text(
                    'VERIFIED NUMBER',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w800,
                      color: Evuddy.greenDeep,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                d.phoneDisplay,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                d.fullName.isEmpty ? 'Rider' : d.fullName,
                style: GoogleFonts.plusJakartaSans(
                  color: Evuddy.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const InfoNote(
          text:
              'Phone number verified. KYC uploads will use this number when the backend is connected.',
        ),
        const SizedBox(height: 14),
        SurfaceCard(
          child: Text(
            'Your information is used for rider KYC and yard pickup. It is not shared as a public listing.',
            style: GoogleFonts.plusJakartaSans(
              color: Evuddy.muted,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
