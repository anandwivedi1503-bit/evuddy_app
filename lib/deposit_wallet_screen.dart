import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'api/evuddy_api.dart';
import 'rider_refund_screen.dart';
import 'services/user_facing_error.dart';
import 'state/registration_draft.dart';
import 'theme/evuddy.dart';
import 'widgets/chrome.dart';

class DepositWalletScreen extends StatefulWidget {
  const DepositWalletScreen({super.key});

  @override
  State<DepositWalletScreen> createState() => _DepositWalletScreenState();
}

class _DepositWalletScreenState extends State<DepositWalletScreen> {
  bool sending = false;
  String? status;

  Future<void> _requestDepositRelease() async {
    final d = registrationDraft;
    final riderId = d.riderId;
    final bookingId = d.depositBookingId ?? d.activeBooking?.bookingId ?? '';
    if (riderId == null || riderId.isEmpty) {
      setState(() => status = 'Complete registration before requesting deposit release.');
      return;
    }
    setState(() {
      sending = true;
      status = null;
    });
    try {
      final token = await d.freshToken(force: true);
      if (token == null) {
        setState(() {
          sending = false;
          status = 'Sign in with OTP again, then retry.';
        });
        return;
      }
      final desc =
          'Rider app: request security deposit release/refund. Held ${CatalogRates.inr(d.depositHeld)} · ${d.depositLabel}'
          '${bookingId.isNotEmpty ? ' · booking $bookingId' : ''}.';
      await EvuddyApi.createTicket(
        idToken: token,
        bookingId: bookingId.isNotEmpty ? bookingId : 'APP-DEPOSIT',
        userId: riderId,
        category: 'REFUND_REQUEST',
        description: desc,
      );
      if (!mounted) return;
      setState(() {
        sending = false;
        status =
            'Request sent to evuddy.com Support CRM. Ops will review on the dashboard and process refund on Razorpay when due.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        sending = false;
        status = userFacingError(e, fallback: 'Could not send request. Try again or call helpdesk.');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = registrationDraft;
    return AuthScreen(
      kicker: 'Hold only',
      title: 'Security deposit',
      subtitle:
          'Same as evuddy.com: bookings hold ${CatalogRates.inr(CatalogRates.securityDeposit)} refundable deposit. This is not UPI. EVUDDY wallet credit is separate and can pay Book EV when the balance covers the amount.',
      footer: Column(
        children: [
          EvuddyButton(
            sun: true,
            label: sending ? 'Sending…' : 'Request deposit release (CRM)',
            busy: sending,
            onPressed: sending ? null : _requestDepositRelease,
          ),
          const SizedBox(height: 10),
          EvuddyGhostButton(
            label: 'Refund form (full details)',
            onPressed: () => Navigator.push(
              context,
              evuddyRoute(const RiderRefundScreen()),
            ),
          ),
        ],
      ),
      children: [
        if (status != null) ...[
          InfoNote(text: status!),
          const SizedBox(height: 14),
        ],
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
    return const RiderRefundScreen();
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
