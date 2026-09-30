import 'evuddy_api.dart';
import 'partner_pdf.dart';

/// Audience for the fleet-partner calculator.
/// Investors/users see published returns only.
/// Business planner sees scale tables, annual / 48-month totals, and FOCO ops.
enum FleetAudience { investor, planner }

enum FleetInputKind { scooters, rupees }

class FleetQuote {
  const FleetQuote({
    required this.plan,
    required this.fleet,
    required this.investment,
    this.leftoverRupees = 0,
    this.requestedRupees = 0,
  });

  final FleetLine plan;
  final int fleet;
  final int investment;
  final int leftoverRupees;
  final int requestedRupees;

  int get monthly => plan.monthly(fleet);
  int get annual => plan.annual(fleet);
  int get tillTerm => plan.tillTerm(fleet);
  int get monthlyPerScooter => plan.monthly(1);
  int get perScooter => plan.perScooter;
  bool get meetsMin => fleet >= FleetPartner.minFleet;
  int get termMonths => FleetPartner.termMonths;
}

class FleetCalculator {
  static FleetQuote fromScooters({
    required FleetLine plan,
    required int fleet,
  }) {
    final n = fleet < 0 ? 0 : fleet;
    return FleetQuote(
      plan: plan,
      fleet: n,
      investment: plan.invest(n),
    );
  }

  /// Largest whole fleet that fits in [rupees] at the published per-scooter cost.
  static FleetQuote fromRupees({
    required FleetLine plan,
    required int rupees,
  }) {
    final money = rupees < 0 ? 0 : rupees;
    final fleet = plan.perScooter <= 0 ? 0 : money ~/ plan.perScooter;
    return FleetQuote(
      plan: plan,
      fleet: fleet,
      investment: plan.invest(fleet),
      leftoverRupees: money - plan.invest(fleet),
      requestedRupees: money,
    );
  }

  static int parseAmount(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.isEmpty) return 0;
    return int.tryParse(cleaned) ?? 0;
  }

  static List<FleetQuote> scale(FleetLine plan) {
    return FleetPartner.fleets
        .map((n) => fromScooters(plan: plan, fleet: n))
        .toList();
  }
}
