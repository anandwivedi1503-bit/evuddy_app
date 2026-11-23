import 'package:flutter/services.dart';
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

const _fleetPartnerPdfAsset = 'assets/documents/fleet-partner-investment.pdf';

Future<void> shareFleetPartnerPdf() async {
  final data = await rootBundle.load(_fleetPartnerPdfAsset);
  await Printing.sharePdf(
    bytes: data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    filename: 'EVUDDY-Fleet-Partner-Investment-Program.pdf',
  );
}
