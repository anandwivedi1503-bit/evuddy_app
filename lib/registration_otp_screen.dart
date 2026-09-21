import 'package:flutter/material.dart';

import 'kyc_details_screen.dart';
import 'state/registration_draft.dart';
import 'theme/evuddy.dart';
import 'widgets/chrome.dart';

class RegistrationOtpScreen extends StatelessWidget {
  const RegistrationOtpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final d = registrationDraft;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const EvuddyHeader(trailing: StepChip(step: 2, of: 4)),
              const SizedBox(height: 24),
              const WelcomeRule(caption: 'PHONE VERIFIED'),
              const SizedBox(height: 24),
              Text('OTP verification', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 10),
              const Text(
                'The website sends one Firebase SMS. This Figma step is a confirmation only — no second code — so we do not invent a second OTP.',
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Evuddy.wash,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'VERIFIED NUMBER',
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 1.6,
                        fontWeight: FontWeight.w700,
                        color: Evuddy.gold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      d.phoneDisplay,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      d.fullName.isEmpty ? 'Rider' : d.fullName,
                      style: const TextStyle(color: Evuddy.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const InfoNote(
                text: 'Phone Number Verified. KYC uploads will use this number when the backend is connected.',
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Evuddy.wash,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Your information is used for rider KYC and yard pickup. It is not shared as a public listing.',
                  style: TextStyle(color: Evuddy.muted, height: 1.4),
                ),
              ),
              const SizedBox(height: 28),
              EvuddyButton(
                label: 'Continue to KYC',
                onPressed: () {
                  Navigator.push(context, evuddyRoute(const KycDetailsScreen()));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
