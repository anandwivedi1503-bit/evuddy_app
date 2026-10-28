import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/security_alert_hub.dart';
import '../services/trip_countdown_store.dart';
import '../theme/evuddy.dart';
import 'rider_safety_pulse.dart';

/// One compact strip: live trip countdown + unread alert chip (avoids double banners).
class RiderSafetyTopBar extends StatelessWidget {
  const RiderSafetyTopBar({super.key, required this.onOpenAlerts});

  final VoidCallback onOpenAlerts;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: SecurityAlertHub.instance.unread,
      builder: (context, unread, _) {
        final store = TripCountdownStore.instance;
        if (!store.active && unread <= 0) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (store.active)
                RiderSafetyPulse(onOpenAlerts: onOpenAlerts),
              if (unread > 0)
                Padding(
                  padding: EdgeInsets.only(top: store.active ? 6 : 0),
                  child: Material(
                    color: Evuddy.ink,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: onOpenAlerts,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: Row(
                          children: [
                            const Icon(Icons.notifications_active_rounded,
                                color: Evuddy.rapidoYellow, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '$unread trip alert${unread == 1 ? '' : 's'} · tap to open',
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded, color: Colors.white70, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
