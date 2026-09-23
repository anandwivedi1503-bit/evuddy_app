import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'evuddy_api.dart';

Future<void> shareFleetPartnerPdf() async {
  final doc = pw.Document();
  final green = PdfColor.fromInt(0xFF14532D);
  final mint = PdfColor.fromInt(0xFF16A34A);
  final ink = PdfColor.fromInt(0xFF1C1917);

  pw.Widget planRow(String tag, int lakhs) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColor.fromInt(0xFFD1FAE5)),
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(tag, style: pw.TextStyle(color: mint, fontWeight: pw.FontWeight.bold, fontSize: 10)),
                pw.SizedBox(height: 4),
                pw.Text('${CatalogRates.inr(lakhs * 100000)}  ·  ${CatalogRates.scootersPerLakh * lakhs} scooters',
                    style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: ink)),
              ],
            ),
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('${CatalogRates.inr(CatalogRates.investorMonthly(lakhs))} / month',
                  style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: green)),
              pw.Text('${CatalogRates.inr(CatalogRates.investorTerm(lakhs))} in ${CatalogRates.partnerMonths} months',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
              pw.Text('Scrap ${CatalogRates.inr(CatalogRates.scrapValue(lakhs))}',
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
            ],
          ),
        ],
      ),
    );
  }

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      build: (ctx) => [
        pw.Text('EVUDDY', style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: green)),
        pw.Text('Fleet partner brief  ·  India EV rental',
            style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
        pw.SizedBox(height: 16),
        pw.Container(
          padding: const pw.EdgeInsets.all(16),
          color: PdfColor.fromInt(0xFF14532D),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Put scooters to work. Keep 60% of net profit.',
                  style: pw.TextStyle(color: PdfColors.white, fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),
              pw.Text(
                'EVUDDY operates the fleet, KYC, GPS, yard OTP and Razorpay. You fund the vehicles. '
                '${CatalogRates.partnerMonths} month term. Same catalog the rider app and evuddy.com share.',
                style: const pw.TextStyle(color: PdfColors.white, fontSize: 11, lineSpacing: 2),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 18),
        pw.Text('Rider catalog (GST included on rentals)',
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: ink)),
        pw.SizedBox(height: 8),
        pw.Bullet(text: 'Daily  ${CatalogRates.inr(CatalogRates.daily)}  GST included'),
        pw.Bullet(text: 'Weekly  ${CatalogRates.inr(CatalogRates.weekly)}  GST included'),
        pw.Bullet(text: 'Monthly  ${CatalogRates.inr(CatalogRates.monthly)}  GST included'),
        pw.Bullet(
          text:
              'Rent to Own  ${CatalogRates.inr(CatalogRates.rtoDaily)} / day  ·  ${CatalogRates.rtoMonths} months  ·  ${CatalogRates.inr(CatalogRates.securityDeposit)} security deposit held (refunded when the scooter is returned)',
        ),
        pw.SizedBox(height: 16),
        pw.Text('How the 60 / 40 split works',
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: ink)),
        pw.SizedBox(height: 6),
        pw.Text(
          '${CatalogRates.scootersPerLakh} scooters per ₹1 lakh. Daily rental ${CatalogRates.inr(CatalogRates.daily)} GST included. '
          'After operations you keep about ${CatalogRates.inr(CatalogRates.investorPerScooterDay)} per scooter per day (60% of net). '
          'Figures are indicative and follow operational performance.',
          style: const pw.TextStyle(fontSize: 11, lineSpacing: 2),
        ),
        pw.SizedBox(height: 14),
        planRow('STARTER', 1),
        planRow('GROWTH', 5),
        planRow('SCALE', 10),
        pw.SizedBox(height: 8),
        pw.Text('Also on evuddy.com', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
        pw.Bullet(text: 'Dealer  ·  city showroom or pickup hub  ·  ₹5 lakh minimum'),
        pw.Bullet(text: 'Distributor  ·  territory supply  ·  ₹10 lakh minimum'),
        pw.SizedBox(height: 16),
        pw.Text(
          'Apply at https://www.evuddy.com/partners   ·   Helpdesk helpdesk@kebuone.in  ·  +91 8726006512',
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'This PDF is generated from the live rider catalog so the website and app stay aligned. Not a guarantee of returns.',
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
        ),
      ],
    ),
  );

  await Printing.sharePdf(
    bytes: await doc.save(),
    filename: 'EVUDDY-Fleet-Partner-Brief.pdf',
  );
}
