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
      title: 'Number verified',
      subtitle: 'Next we collect KYC. One phone check — no second SMS.',
      step: 2,
      footer: EvuddyButton(
        label: 'Continue to KYC',
        onPressed: () {
          Navigator.push(context, evuddyRoute(const KycDetailsScreen()));
        },
      ),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Evuddy.field,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.verified_rounded, color: Evuddy.green, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Verified',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Evuddy.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                d.phoneDisplay,
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                d.fullName.isEmpty ? 'Rider' : d.fullName,
                style: GoogleFonts.inter(color: Evuddy.muted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
