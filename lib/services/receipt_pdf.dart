import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../api/evuddy_api.dart';
import '../state/registration_draft.dart';

class ReceiptPdf {
  const ReceiptPdf._();

  static Future<void> share(PaymentReceipt receipt) async {
    final d = registrationDraft;
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('EVUDDY', style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold)),
            pw.Text('Smart electric mobility · GST-inclusive rental receipt'),
            pw.SizedBox(height: 24),
            pw.Text('Payment receipt', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 16),
            _row('Rider', d.fullName.isEmpty ? 'Rider' : d.fullName),
            _row('Rider ID', d.riderId ?? '—'),
            _row('Mobile', d.phoneDisplay.isEmpty ? d.phone : d.phoneDisplay),
            _row('Email', d.email.isEmpty ? '—' : d.email),
            _row('Booking ID', receipt.bookingId.isEmpty ? '—' : receipt.bookingId),
            _row('Amount paid', CatalogRates.inr(receipt.amount)),
            _row('Payment mode', receipt.paymentMethod.isEmpty ? 'Razorpay UPI / card' : receipt.paymentMethod),
            _row('Invoice / receipt no.', receipt.invoiceNumber.isEmpty ? '—' : receipt.invoiceNumber),
            _row('Transaction ID', receipt.transactionId.isEmpty ? '—' : receipt.transactionId),
            pw.SizedBox(height: 24),
            pw.Text(
              'This receipt matches the Razorpay payment recorded on evuddy.com. '
              'Security deposit refunds are separate and return to the original payment method after yard return.',
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.Spacer(),
            pw.Text('helpdesk@kebuone.in · +91 8726006512 · www.evuddy.com'),
          ],
        ),
      ),
    );
    final bytes = await doc.save();
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'EVUDDY-receipt-${receipt.bookingId.isEmpty ? "payment" : receipt.bookingId}.pdf',
    );
  }

  static pw.Widget _row(String label, String value) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 8),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 120,
              child: pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
            pw.Expanded(child: pw.Text(value)),
          ],
        ),
      );
}
