import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'evuddy_api.dart';

class FleetLine {
  const FleetLine({
    required this.title,
    required this.perScooter,
    required this.monthlyForFive,
  });

  final String title;
  final int perScooter;
  final int monthlyForFive;

  int invest(int fleet) => perScooter * fleet;
  int monthly(int fleet) => (monthlyForFive ~/ 5) * fleet;
  int annual(int fleet) => monthly(fleet) * 12;
  int tillTerm(int fleet) => monthly(fleet) * CatalogRates.partnerMonths;
}

class FleetPartner {
  static const termMonths = 48;
  static const minFleet = 5;
  static const fleets = [5, 10, 15, 20, 30, 50, 100];

  static const low = FleetLine(
    title: 'Low-speed EV scooter',
    perScooter: 60000,
    monthlyForFive: 15000,
  );

  static const high = FleetLine(
    title: 'High-speed EV scooter',
    perScooter: 90000,
    monthlyForFive: 18000,
  );
}

Future<void> shareFleetPartnerPdf() async {
  try {
    final data = await rootBundle.load('assets/docs/fleet_partner_investment.pdf');
    await Printing.sharePdf(
      bytes: data.buffer.asUint8List(),
      filename: 'EVUDDY-Fleet-Partner-Investment-Program.pdf',
    );
    return;
  } catch (_) {}
  await _shareGeneratedFleetPartnerPdf();
}

Future<void> _shareGeneratedFleetPartnerPdf() async {
  final doc = pw.Document();
  final green = PdfColor.fromInt(0xFF16A34A);
  final deep = PdfColor.fromInt(0xFF14532D);
  final pink = PdfColor.fromInt(0xFFEC4899);
  final ink = PdfColor.fromInt(0xFF1C1917);
  final wash = PdfColor.fromInt(0xFFF7F8F5);
  final line = PdfColor.fromInt(0xFFD6E4D6);

  pw.Widget pill(String text) => pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: pw.BoxDecoration(
          color: PdfColor.fromInt(0xFFECFDF3),
          borderRadius: pw.BorderRadius.circular(99),
        ),
        child: pw.Text(text,
            style: pw.TextStyle(color: deep, fontWeight: pw.FontWeight.bold, fontSize: 9)),
      );

  pw.Widget h1(String a, String b) => pw.Row(
        children: [
          pw.Text(a, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: deep)),
          pw.Text(' $b', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: pink)),
        ],
      );

  pw.Widget kvTable(List<(String, String)> rows) {
    return pw.Table(
      border: pw.TableBorder.all(color: line, width: 0.6),
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: green),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Particular',
                  style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Details',
                  style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10)),
            ),
          ],
        ),
        for (var i = 0; i < rows.length; i++)
          pw.TableRow(
            decoration: pw.BoxDecoration(color: i.isEven ? wash : PdfColors.white),
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(rows[i].$1, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(rows[i].$2,
                    style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: ink)),
              ),
            ],
          ),
      ],
    );
  }

  pw.Widget scaleTable(FleetLine plan) {
    return pw.Table(
      border: pw.TableBorder.all(color: line, width: 0.5),
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: green),
          children: [
            for (final h in [
              'Fleet',
              'Per scooter',
              'Investment',
              'Monthly',
              'Annual',
              'Till 48 months',
            ])
              pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(h,
                    style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 8)),
              ),
          ],
        ),
        for (var i = 0; i < FleetPartner.fleets.length; i++)
          pw.TableRow(
            decoration: pw.BoxDecoration(color: i.isEven ? wash : PdfColors.white),
            children: [
              for (final v in [
                '${FleetPartner.fleets[i]}',
                CatalogRates.inr(plan.perScooter),
                CatalogRates.inr(plan.invest(FleetPartner.fleets[i])),
                CatalogRates.inr(plan.monthly(FleetPartner.fleets[i])),
                CatalogRates.inr(plan.annual(FleetPartner.fleets[i])),
                CatalogRates.inr(plan.tillTerm(FleetPartner.fleets[i])),
              ])
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(v, style: pw.TextStyle(fontSize: 8, color: ink)),
                ),
            ],
          ),
      ],
    );
  }

  pw.Widget planBlock(FleetLine line) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(line.title.toUpperCase(),
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: ink)),
        pw.SizedBox(height: 6),
        pw.Wrap(spacing: 8, runSpacing: 6, children: [
          pill('Minimum fleet: ${FleetPartner.minFleet} scooters'),
          pill('Investment / scooter: ${CatalogRates.inr(line.perScooter)}'),
          pill('Minimum investment: ${CatalogRates.inr(line.invest(FleetPartner.minFleet))}'),
          pill('Monthly return: ${CatalogRates.inr(line.monthlyForFive)}'),
        ]),
        pw.SizedBox(height: 10),
        kvTable([
          ('Minimum scooters', '${FleetPartner.minFleet}'),
          ('Cost / scooter', CatalogRates.inr(line.perScooter)),
          ('Total investment', CatalogRates.inr(line.invest(FleetPartner.minFleet))),
          ('Monthly return', CatalogRates.inr(line.monthlyForFive)),
          ('Operations', '100% EVUDDY'),
          ('Model', 'FOCO'),
          ('Investor role', 'Fleet owner'),
          ('Operator', 'EVUDDY'),
        ]),
        pw.SizedBox(height: 6),
        pw.Text(
          '${FleetPartner.minFleet} scooters × ${CatalogRates.inr(line.perScooter)} = ${CatalogRates.inr(line.invest(FleetPartner.minFleet))}   ·   Monthly return = ${CatalogRates.inr(line.monthlyForFive)}',
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
        ),
      ],
    );
  }

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (ctx) => [
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(22),
          decoration: pw.BoxDecoration(color: deep, borderRadius: pw.BorderRadius.circular(12)),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('EVUDDY',
                  style: pw.TextStyle(color: PdfColors.white, fontSize: 26, fontWeight: pw.FontWeight.bold)),
              pw.Text('SMART · ELECTRIC · MOBILITY  ·  BY KEBU ONE',
                  style: const pw.TextStyle(color: PdfColors.white, fontSize: 9, letterSpacing: 1.2)),
              pw.SizedBox(height: 12),
              pw.Text('FLEET PARTNER INVESTMENT PROGRAM',
                  style: pw.TextStyle(color: PdfColors.white, fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Text('Own the fleet. We operate everything.',
                  style: const pw.TextStyle(color: PdfColors.white, fontSize: 12)),
            ],
          ),
        ),
        pw.SizedBox(height: 16),
        h1('ABOUT', 'EVUDDY'),
        pw.SizedBox(height: 8),
        pw.Text(
          'EVUDDY is building India’s next-generation electric mobility ecosystem through B2B, B2C and Rent-to-Own solutions. '
          'The Fleet Partner Investment Program lets individuals, businesses and investors own a fleet of EV scooters while EVUDDY takes complete responsibility for operations — rider acquisition, rental management, deployment, maintenance, tracking and day-to-day fleet operations.',
          style: const pw.TextStyle(fontSize: 11, lineSpacing: 2.2),
        ),
        pw.SizedBox(height: 8),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(12),
          color: wash,
          child: pw.Text('You own the fleet. EVUDDY operates the fleet. You receive monthly returns.',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: deep)),
        ),
        pw.SizedBox(height: 16),
        h1('WHY EVUDDY', 'FLEET PARTNERSHIP?'),
        pw.SizedBox(height: 8),
        pw.Bullet(text: 'Own real EV assets — predefined monthly return by category and fleet size.'),
        pw.Bullet(text: 'Passive fleet income — EVUDDY runs day-to-day operations (FOCO).'),
        pw.Bullet(text: 'Company-operated model — no managing riders, collections or operations yourself.'),
        pw.Bullet(text: 'Scalable — start at 5 scooters and grow with the network.'),
        pw.Bullet(text: 'Technology-led — GPS scooters, KYC, hub OTP pickup and digital rental.'),
        pw.Bullet(text: 'Multiple segments — commuters, gig workers and delivery riders.'),
        pw.SizedBox(height: 16),
        h1('INVESTMENT', 'PLANS'),
        pw.SizedBox(height: 10),
        planBlock(FleetPartner.low),
        pw.SizedBox(height: 16),
        planBlock(FleetPartner.high),
        pw.SizedBox(height: 16),
        h1('SCALE YOUR', 'EV FLEET'),
        pw.SizedBox(height: 6),
        pw.Text('Low-speed', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: deep, fontSize: 11)),
        pw.SizedBox(height: 6),
        scaleTable(FleetPartner.low),
        pw.SizedBox(height: 12),
        pw.Text('High-speed', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: deep, fontSize: 11)),
        pw.SizedBox(height: 6),
        scaleTable(FleetPartner.high),
        pw.SizedBox(height: 8),
        pw.Text(
          'Returns shown are calculated proportionately from the stated per-fleet monthly return and are subject to the final Fleet Partner Agreement.',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 16),
        h1('HOW THE EVUDDY', 'FOCO MODEL WORKS'),
        pw.SizedBox(height: 8),
        pw.Bullet(text: '1  Invest — select EV category and fleet size.'),
        pw.Bullet(text: '2  Fleet allocation — EVUDDY allocates the corresponding scooters.'),
        pw.Bullet(text: '3  EVUDDY deploys — scooters enter the rental ecosystem by operational need.'),
        pw.Bullet(text: '4  EVUDDY operates — riders, rentals, utilisation, technology, day-to-day ops.'),
        pw.Bullet(text: '5  Monthly return — as agreed in the applicable Fleet Partner plan and agreement.'),
        pw.Bullet(text: '6  Scale — expand the fleet as the EVUDDY network grows.'),
        pw.SizedBox(height: 14),
        h1('WHAT EVUDDY', 'MANAGES'),
        pw.SizedBox(height: 6),
        pw.Text(
          'Fleet deployment · Rider acquisition · Rental management · KYC & verification · GPS & technology · Hub operations (OTP pickup) · Maintenance & support · Customer support.',
          style: const pw.TextStyle(fontSize: 10, lineSpacing: 2),
        ),
        pw.SizedBox(height: 14),
        h1('WHO CAN BECOME A', 'FLEET PARTNER?'),
        pw.SizedBox(height: 6),
        pw.Bullet(text: 'Q1  Individual investors — participate in the EV mobility ecosystem.'),
        pw.Bullet(text: 'Q2  Business owners — diversify into electric mobility.'),
        pw.Bullet(text: 'Q3  Entrepreneurs — rental-sector exposure without building ops infrastructure.'),
        pw.Bullet(text: 'Q4  Existing fleet owners — plug vehicles into a technology-enabled rental ecosystem.'),
        pw.SizedBox(height: 16),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(border: pw.Border.all(color: line), borderRadius: pw.BorderRadius.circular(8)),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('IMPORTANT NOTE',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: deep, fontSize: 11)),
              pw.SizedBox(height: 6),
              pw.Text(
                'Investment amount, monthly return, tenure, vehicle ownership structure, maintenance, insurance, depreciation, exit/termination and other commercial terms are governed by the final Fleet Partner Agreement between EVUDDY / Shubhrax Mobility Ltd. and the Fleet Partner. '
                'Monthly return figures in this brief follow the published plans and are not a guarantee beyond the executed agreement.',
                style: const pw.TextStyle(fontSize: 9, lineSpacing: 2),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 14),
        pw.Text('www.evuddy.com/partners   ·   helpdesk@kebuone.in   ·   +91 8726006512',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
      ],
    ),
  );

  await Printing.sharePdf(
    bytes: await doc.save(),
    filename: 'EVUDDY-Fleet-Partner-Investment-Program.pdf',
  );
}
