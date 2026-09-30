import 'package:evuddy_app/api/evuddy_api.dart';
import 'package:evuddy_app/api/fleet_calculator.dart';
import 'package:evuddy_app/api/partner_pdf.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('5 low-speed scooters match the fleet partner PDF', () {
    final q = FleetCalculator.fromScooters(plan: FleetPartner.low, fleet: 5);
    expect(q.investment, 300000);
    expect(q.monthly, 15000);
    expect(q.annual, 180000);
    expect(q.tillTerm, 720000);
    expect(q.meetsMin, isTrue);
    expect(q.monthlyPerScooter, 3000);
  });

  test('5 high-speed scooters match the fleet partner PDF', () {
    final q = FleetCalculator.fromScooters(plan: FleetPartner.high, fleet: 5);
    expect(q.investment, 450000);
    expect(q.monthly, 18000);
    expect(q.annual, 216000);
    expect(q.tillTerm, 864000);
  });

  test('rupee input allocates whole scooters and leftover', () {
    final q = FleetCalculator.fromRupees(plan: FleetPartner.low, rupees: 320000);
    expect(q.fleet, 5);
    expect(q.investment, 300000);
    expect(q.leftoverRupees, 20000);
    expect(q.monthly, 15000);
    final short = FleetCalculator.fromRupees(plan: FleetPartner.low, rupees: 50000);
    expect(short.fleet, 0);
    expect(short.leftoverRupees, 50000);
    expect(short.meetsMin, isFalse);
  });

  test('parses Indian rupee strings', () {
    expect(FleetCalculator.parseAmount('₹3,00,000'), 300000);
    expect(FleetCalculator.parseAmount('10'), 10);
    expect(FleetCalculator.parseAmount(''), 0);
  });

  test('scale table uses published fleets', () {
    final rows = FleetCalculator.scale(FleetPartner.high);
    expect(rows.map((e) => e.fleet), FleetPartner.fleets);
    expect(rows.first.investment, 450000);
    expect(CatalogRates.inr(rows.first.monthly), '₹18,000');
  });
}
