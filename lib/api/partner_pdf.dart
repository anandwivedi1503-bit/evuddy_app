import 'package:http/http.dart' as http;
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

/// Same file the website serves at /fleet-partner-investment.pdf.
Future<void> shareFleetPartnerPdf() async {
  final uri = Uri.parse('${EvuddyApi.origin}/fleet-partner-investment.pdf');
  final response = await http.get(uri).timeout(const Duration(seconds: 25));
  final bytes = response.bodyBytes;
  final looksLikePdf = bytes.length > 5 &&
      bytes[0] == 0x25 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x44 &&
      bytes[3] == 0x46;
  if (response.statusCode != 200 || !looksLikePdf) {
    throw ApiException(
      'Could not download the fleet partner PDF from evuddy.com. Check mobile data or Wi-Fi and try again.',
    );
  }
  await Printing.sharePdf(
    bytes: bytes,
    filename: 'EVUDDY-Fleet-Partner-Investment.pdf',
  );
}
