import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../api/evuddy_api.dart';
import '../services/booking_end_schedule.dart';
import '../theme/evuddy.dart';

class RentalUnitsStepper extends StatelessWidget {
  const RentalUnitsStepper({
    super.key,
    required this.duration,
    required this.units,
    required this.onChanged,
  });

  final String duration;
  final int units;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final max = BookingEndSchedule.maxUnits(duration);
    final u = units.clamp(1, max);
    final label = BookingEndSchedule.unitLabel(duration);
    final fare = CatalogRates.amountForDuration(duration, units: u);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Evuddy.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            duration == 'Hourly' ? 'HOW MANY HOURS?' : 'PLAN LENGTH',
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _RoundIconButton(
                icon: Icons.remove_rounded,
                onTap: u > 1
                    ? () {
                        HapticFeedback.selectionClick();
                        onChanged(u - 1);
                      }
                    : null,
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '$u',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      label,
                      style: GoogleFonts.plusJakartaSans(
                        color: Evuddy.muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              _RoundIconButton(
                icon: Icons.add_rounded,
                onTap: u < max
                    ? () {
                        HapticFeedback.selectionClick();
                        onChanged(u + 1);
                      }
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Fare auto-calculated · ${CatalogRates.inr(fare)} GST included',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              color: Evuddy.greenDeep,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: enabled ? Evuddy.rapidoYellow : Evuddy.line.withValues(alpha: 0.4),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: Evuddy.ink),
        ),
      ),
    );
  }
}
