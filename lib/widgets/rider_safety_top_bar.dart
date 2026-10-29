import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/security_alert_hub.dart';
import '../services/trip_countdown_store.dart';
import '../state/registration_draft.dart';
import '../theme/evuddy.dart';

/// Compact blinking entry to Trip safety screen — countdown lives on that screen only.
class RiderSafetyTopBar extends StatefulWidget {
  const RiderSafetyTopBar({super.key, required this.onOpenAlerts});

  final VoidCallback onOpenAlerts;

  @override
  State<RiderSafetyTopBar> createState() => _RiderSafetyTopBarState();
}

class _RiderSafetyTopBarState extends State<RiderSafetyTopBar> with SingleTickerProviderStateMixin {
  late final AnimationController _blink;

  @override
  void initState() {
    super.initState();
    _blink = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))
      ..repeat(reverse: true);
    SecurityAlertHub.instance.unread.addListener(_rebuild);
    TripCountdownStore.instance.tick.addListener(_rebuild);
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    SecurityAlertHub.instance.unread.removeListener(_rebuild);
    TripCountdownStore.instance.tick.removeListener(_rebuild);
    _blink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!registrationDraft.phoneVerified) return const SizedBox.shrink();
    final unread = SecurityAlertHub.instance.unread.value;
    final tripLive = TripCountdownStore.instance.active;
    if (!tripLive && unread <= 0) return const SizedBox.shrink();

    final urgent = tripLive &&
        (TripCountdownStore.instance.timeUntilEnd ?? const Duration(days: 1)) <=
            const Duration(hours: 1);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 2),
      child: Material(
        color: urgent ? const Color(0xFF7F1D1D) : Evuddy.ink,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: widget.onOpenAlerts,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                FadeTransition(
                  opacity: Tween<double>(begin: 0.35, end: 1).animate(
                    CurvedAnimation(parent: _blink, curve: Curves.easeInOut),
                  ),
                  child: Icon(
                    urgent ? Icons.notifications_active_rounded : Icons.shield_moon_outlined,
                    color: Evuddy.rapidoYellow,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tripLive
                        ? 'Trip alerts · timer inside'
                        : '$unread alert${unread == 1 ? '' : 's'}',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (unread > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Evuddy.magenta,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      '$unread',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right_rounded, color: Colors.white70, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
