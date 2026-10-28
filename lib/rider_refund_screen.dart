import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'api/evuddy_api.dart';
import 'state/registration_draft.dart';
import 'theme/evuddy.dart';
import 'widgets/chrome.dart';

/// Rider self-service deposit refund — not the ops CRM.
class RiderRefundScreen extends StatefulWidget {
  const RiderRefundScreen({super.key});

  @override
  State<RiderRefundScreen> createState() => _RiderRefundScreenState();
}

class _RiderRefundScreenState extends State<RiderRefundScreen> {
  bool busy = false;
  String? note;
  String? error;

  Future<void> _request() async {
    final d = registrationDraft;
    final bookingId = d.depositBookingId ?? d.activeBooking?.bookingId ?? '';
    if (bookingId.isEmpty) {
      setState(() => error = 'No deposit hold linked to a booking yet.');
      return;
    }
    setState(() {
      busy = true;
      error = null;
      note = null;
    });
    try {
      final token = await d.freshToken(force: true);
      if (token == null) throw ApiException('Confirm mobile with OTP first.');
      final amount = d.depositHeld > 0 ? d.depositHeld : CatalogRates.securityDeposit.toDouble();
      final result = await EvuddyApi.requestDepositRefund(
        idToken: token,
        bookingId: bookingId,
        amountRupees: amount,
      );
      if (!mounted) return;
      setState(() {
        busy = false;
        note = result.message;
        if (result.ok) d.depositStatus = 'refund_pending';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        busy = false;
        error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = registrationDraft;
    return AuthScreen(
      kicker: 'Rider',
      title: 'Deposit refund',
      subtitle:
          'After the yard takes the scooter back, your ₹2,500 hold returns on the same Razorpay payment. Finance confirms on evuddy.com admin — not in this rider app.',
      error: error,
      footer: EvuddyButton(
        sun: true,
        label: busy ? 'Requesting…' : 'Request refund to Razorpay',
        busy: busy,
        onPressed: busy ? null : _request,
      ),
      children: [
        if (note != null) ...[
          InfoNote(text: note!),
          const SizedBox(height: 12),
        ],
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hold status', style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: 8),
              Text(
                CatalogRates.inr(d.depositHeld),
                style: GoogleFonts.plusJakartaSans(fontSize: 32, fontWeight: FontWeight.w800),
              ),
              Text(d.depositLabel, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ],
    );
  }
}
