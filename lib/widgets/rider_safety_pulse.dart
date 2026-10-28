import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/rider_safety_tracker.dart';
import '../services/trip_countdown_store.dart';
import '../theme/evuddy.dart';

/// Rider phone: pulsing siren-style countdown while a trip is active.
class RiderSafetyPulse extends StatefulWidget {
  const RiderSafetyPulse({super.key, required this.onOpenAlerts});

  final VoidCallback onOpenAlerts;

  @override
  State<RiderSafetyPulse> createState() => _RiderSafetyPulseState();
}

class _RiderSafetyPulseState extends State<RiderSafetyPulse> with SingleTickerProviderStateMixin {
  Timer? _clock;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    TripCountdownStore.instance.tick.addListener(_onTick);
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      TripCountdownStore.instance.tick.value++;
    });
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _clock?.cancel();
    _pulse.dispose();
    TripCountdownStore.instance.tick.removeListener(_onTick);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    TripCountdownStore.instance.tick.value;
    final store = TripCountdownStore.instance;
    if (!store.active) return const SizedBox.shrink();
    final untilEnd = store.timeUntilEnd ?? Duration.zero;
    final untilReminder = store.timeUntilReminder ?? Duration.zero;
    final gpsOn = RiderSafetyTracker.instance.active;
    final urgent = untilEnd <= const Duration(hours: 1);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Material(
        elevation: urgent ? 6 : 2,
        shadowColor: Evuddy.magenta.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: widget.onOpenAlerts,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                colors: urgent
                    ? [const Color(0xFF7F1D1D), const Color(0xFFDC2626), const Color(0xFFF97316)]
                    : [const Color(0xFF1E3A8A), const Color(0xFF2563EB)],
              ),
            ),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(
              children: [
                ScaleTransition(
                  scale: Tween<double>(begin: 0.92, end: 1.08).animate(
                    CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
                  ),
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Icon(
                      urgent ? Icons.campaign_rounded : Icons.shield_moon_outlined,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        urgent ? 'RETURN SOON · PLAN ENDING' : 'TRIP SAFETY LIVE',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ends in ${TripCountdownStore.formatDuration(untilEnd)}',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                        ),
                      ),
                      Text(
                        [
                          if (store.durationLabel.isNotEmpty) store.durationLabel,
                          if (untilReminder > Duration.zero)
                            'Reminder in ${TripCountdownStore.formatDuration(untilReminder)}',
                          if (gpsOn) 'Phone GPS shared with EVUDDY ops',
                        ].join(' · '),
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white.withValues(alpha: 0.88),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
