import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'api/evuddy_api.dart';
import 'services/receipt_pdf.dart';
import 'state/registration_draft.dart';
import 'theme/evuddy.dart';
import 'widgets/chrome.dart';

class ReceiptDetailScreen extends StatelessWidget {
  const ReceiptDetailScreen({super.key, required this.receipt});

  final PaymentReceipt receipt;

  @override
  Widget build(BuildContext context) {
    final d = registrationDraft;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Payment receipt',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                colors: [Color(0xFF052E16), Color(0xFF16A34A)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PAID',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white70,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  CatalogRates.inr(receipt.amount),
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  receipt.paymentMethod.isEmpty ? 'Razorpay' : receipt.paymentMethod,
                  style: GoogleFonts.plusJakartaSans(color: Colors.white70, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SurfaceCard(
            child: Column(
              children: [
                _DetailRow('Rider', d.fullName.isEmpty ? 'Rider' : d.fullName),
                _DetailRow('Rider ID', d.riderId ?? '—'),
                _DetailRow('Mobile', d.phoneDisplay.isEmpty ? d.phone : d.phoneDisplay),
                _DetailRow('Email', d.email.isEmpty ? '—' : d.email),
                _DetailRow('Booking ID', receipt.bookingId.isEmpty ? '—' : receipt.bookingId),
                _DetailRow(
                  'Invoice no.',
                  receipt.invoiceNumber.isEmpty ? '—' : receipt.invoiceNumber,
                ),
                _DetailRow(
                  'Transaction ID',
                  receipt.transactionId.isEmpty ? '—' : receipt.transactionId,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const InfoNote(
            text:
                'Download a PDF for your records or share on WhatsApp / email. EVUDDY ops see the same receipt on evuddy.com admin CRM.',
          ),
          const SizedBox(height: 16),
          EvuddyButton(
            sun: true,
            label: 'Download PDF receipt',
            onPressed: () => ReceiptPdf.share(receipt),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                color: Evuddy.muted,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
