import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'api/evuddy_api.dart';
import 'dashboards/command_center_screen.dart';
import 'state/registration_draft.dart';
import 'theme/evuddy.dart';
import 'widgets/chrome.dart';

class DepositWalletScreen extends StatelessWidget {
  const DepositWalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final d = registrationDraft;
    return AuthScreen(
      kicker: 'Hold only',
      title: 'Security deposit',
      subtitle:
          'Same as evuddy.com: bookings hold ${CatalogRates.inr(CatalogRates.securityDeposit)} refundable deposit. This is not UPI. EVUDDY wallet credit is separate and can pay Book EV when the balance covers the amount.',
      footer: EvuddyButton(
        label: 'Open refunds',
        onPressed: () => Navigator.push(
          context,
          evuddyRoute(const CommandCenterScreen(initialTab: 2)),
        ),
      ),
      children: [
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('HELD AT YARD', style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: 8),
              Text(
                CatalogRates.inr(d.depositHeld),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: Evuddy.greenDeep,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                d.depositLabel,
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
              ),
              if (d.depositBookingId != null) ...[
                const SizedBox(height: 6),
                Text(
                  'Booking ${d.depositBookingId}',
                  style: GoogleFonts.plusJakartaSans(color: Evuddy.muted, fontSize: 13),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        const InfoNote(
          text:
              'GST-included fare plus ₹2,500 deposit on every Book EV, matching the website. Deposit is refunded after return. EVUDDY wallet is credit from refunds/admin — not PhonePe.',
        ),
        const SizedBox(height: 14),
        _Step(n: '1', t: 'Pay hold', d: 'Razorpay ${CatalogRates.inr(CatalogRates.securityDeposit)} deposit with the fare.'),
        _Step(n: '2', t: 'Ride', d: 'Yard keeps the hold while the scooter is with you.'),
        _Step(n: '3', t: 'Return', d: 'Ride-end OTP at the hub starts the refund.'),
      ],
    );
  }
}

class RefundDashboardScreen extends StatelessWidget {
  const RefundDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CommandCenterScreen(initialTab: 2);
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.n, required this.t, required this.d});
  final String n;
  final String t;
  final String d;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SurfaceCard(
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Evuddy.greenSoft,
              child: Text(n, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: Evuddy.greenDeep)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
                  Text(d, style: GoogleFonts.plusJakartaSans(color: Evuddy.muted, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
