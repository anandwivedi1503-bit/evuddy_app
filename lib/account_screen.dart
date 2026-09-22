import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'invest_screen.dart';
import 'open_link.dart';
import 'state/registration_draft.dart';
import 'theme/evuddy.dart';
import 'widgets/chrome.dart';
import 'widgets/promo.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key, this.onLoggedOut});
  final VoidCallback? onLoggedOut;

  @override
  Widget build(BuildContext context) {
    final d = registrationDraft;
    final status = !d.phoneVerified
        ? 'Not signed in'
        : d.canBook
            ? 'Approved · Book EV open'
            : (d.approvalStatus.isEmpty ? 'KYC pending' : d.approvalStatus);
    return AuthScreen(
      showBack: false,
      kicker: 'Account',
      title: d.fullName.isEmpty ? 'Your EVUDDY' : d.fullName,
      subtitle: status,
      footer: EvuddyGhostButton(
        label: 'Log out on this phone',
        onPressed: () {
          registrationDraft
            ..phoneVerified = false
            ..firebaseIdToken = null
            ..firebaseUid = null
            ..bookingEnabled = false
            ..approvalStatus = ''
            ..chosenPlan = null
            ..riderId = null;
          onLoggedOut?.call();
        },
      ),
      children: [
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                d.phoneDisplay.isEmpty ? 'No number yet' : d.phoneDisplay,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                d.email.isEmpty ? 'Complete KYC to unlock hubs' : d.email,
                style: GoogleFonts.plusJakartaSans(color: Evuddy.muted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const TrustStrip(),
        const SizedBox(height: 16),
        const InvestAdCarousel(),
        const SizedBox(height: 14),
        EvuddyButton(
          label: 'Investment plans',
          onPressed: () => Navigator.push(context, evuddyRoute(const InvestScreen())),
        ),
        const SizedBox(height: 10),
        EvuddyGhostButton(
          label: 'Call helpdesk 24×7',
          onPressed: dialHelpdesk,
        ),
        const SizedBox(height: 14),
        const InfoNote(
          text:
              'OTP uses Firebase on evuddy.com. We never store your SMS inbox. Helpdesk · helpdesk@kebuone.in · +91 8726006512',
        ),
      ],
    );
  }
}
