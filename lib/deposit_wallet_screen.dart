import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'api/evuddy_api.dart';
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
          'This is not a recharge wallet. Rent to Own holds ${CatalogRates.inr(CatalogRates.securityDeposit)}. When the scooter is back we release it from Refunds.',
      footer: EvuddyButton(
        label: 'Open refunds',
        onPressed: () => Navigator.push(context, evuddyRoute(const RefundDashboardScreen())),
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
              'Rental plans do not take a deposit. Rent to Own: ₹300 / day for 20 months plus this one-time hold. No top-ups, no wallet spend.',
        ),
        const SizedBox(height: 14),
        _Step(n: '1', t: 'Pay hold', d: 'Razorpay ${CatalogRates.inr(CatalogRates.securityDeposit)} on Rent to Own.'),
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
    final d = registrationDraft;
    final pending = d.depositStatus == 'refund_pending';
    final released = d.depositStatus == 'released';
    return AuthScreen(
      kicker: 'Refunds',
      title: 'Deposit release',
      subtitle: 'Admin-friendly view of the hold. Same booking the website sees after Razorpay.',
      children: [
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                pending
                    ? 'Refund queued'
                    : released
                        ? 'Released to source'
                        : d.depositHeld > 0
                            ? 'On hold'
                            : 'Nothing to refund',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                'Amount ${CatalogRates.inr(d.depositHeld > 0 ? d.depositHeld : CatalogRates.securityDeposit)}',
                style: GoogleFonts.plusJakartaSans(color: Evuddy.muted),
              ),
              const SizedBox(height: 12),
              Text(
                pending
                    ? 'Scooter is back. Finance can refund the hold on Razorpay / the same bank path.'
                    : released
                        ? 'Hold is marked released on this phone. Bank timing follows Razorpay.'
                        : 'Refunds start only after ride-end OTP. There is no recharge balance.',
                style: GoogleFonts.plusJakartaSans(height: 1.45),
              ),
            ],
          ),
        ),
      ],
    );
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
