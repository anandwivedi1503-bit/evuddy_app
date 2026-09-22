import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'api/evuddy_api.dart';
import 'state/registration_draft.dart';
import 'theme/evuddy.dart';
import 'widgets/chrome.dart';

class RideReadyScreen extends StatefulWidget {
  const RideReadyScreen({super.key});

  @override
  State<RideReadyScreen> createState() => _RideReadyScreenState();
}

class _RideReadyScreenState extends State<RideReadyScreen> {
  String duration = registrationDraft.chosenDuration ?? 'Daily';

  @override
  Widget build(BuildContext context) {
    final d = registrationDraft;
    final rental = d.chosenPlan != 'rto';
    return AuthScreen(
      kicker: rental ? 'Flexible rental' : 'Rent to Own',
      title: rental ? 'Choose a duration' : '18-month ownership',
      subtitle: rental
          ? 'Same catalog as the website. Razorpay checkout is the next connect — not charged in this build.'
          : '₹${CatalogRates.rtoDaily}/day · ${CatalogRates.rtoMonths} months · hub OTP after pay.',
      footer: EvuddyButton(
        label: 'Place hold at hub',
        onPressed: () {
          registrationDraft.chosenDuration = duration;
          showModalBottomSheet<void>(
            context: context,
            backgroundColor: Colors.white,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            builder: (ctx) => Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_rounded, color: Evuddy.green, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'You’re queued at the yard',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pay + pickup OTP is the live website Book EV checkout (Razorpay). We’ll attach that next without editing the website.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(color: Evuddy.muted),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      children: [
        const ScenePhoto(asset: Evuddy.riderEveningAsset, height: 200),
        const SizedBox(height: 16),
        Center(
          child: Text(
            'EVUDDY Electric Scooter',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 18),
          ),
        ),
        const SizedBox(height: 4),
        const Center(child: Text('120 km · 45 km/h · GPS · zero tailpipe')),
        const SizedBox(height: 20),
        if (rental)
          ChoicePills(
            options: const ['Hourly', 'Daily', 'Weekly', 'Monthly'],
            value: duration,
            onChanged: (v) => setState(() => duration = v),
          ),
        const SizedBox(height: 16),
        SurfaceCard(
          child: Text(
            '${d.chosenCity ?? "City"} hub · ${rental ? duration : "Rent to Own"} · ${CatalogRates.gstNote}',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
