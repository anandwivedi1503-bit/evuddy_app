import 'package:flutter/material.dart';

import 'login_screen.dart';
import 'state/registration_draft.dart';
import 'theme/evuddy.dart';
import 'widgets/chrome.dart';

class SubmittedScreen extends StatelessWidget {
  const SubmittedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final d = registrationDraft;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
          child: Column(
            children: [
              const EvuddyHeader(),
              const Spacer(),
              const WelcomeRule(caption: 'APPLICATION RECEIVED'),
              const SizedBox(height: 28),
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: Evuddy.greenSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, size: 36, color: Evuddy.green),
              ),
              const SizedBox(height: 22),
              Text(
                'Thank you, ${d.fullName.split(' ').first}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 10),
              const Text(
                'Your rider KYC is complete in the app. Ops still has to approve it before Book EV — same as evuddy.com. Nothing was sent to the server in this step.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              Text(
                d.phoneDisplay,
                style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.4),
              ),
              const Spacer(),
              EvuddyButton(
                label: 'Back to mobile number',
                icon: Icons.home_outlined,
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
