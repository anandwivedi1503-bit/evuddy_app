import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'services/rider_safety_tracker.dart';
import 'services/security_alert_hub.dart';
import 'services/trip_countdown_store.dart';
import 'theme/evuddy.dart';
import 'widgets/chrome.dart';

class SecurityAlertsScreen extends StatefulWidget {
  const SecurityAlertsScreen({super.key});

  @override
  State<SecurityAlertsScreen> createState() => _SecurityAlertsScreenState();
}

class _SecurityAlertsScreenState extends State<SecurityAlertsScreen>
    with SingleTickerProviderStateMixin {
  Timer? _clock;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 850))
      ..repeat(reverse: true);
    SecurityAlertHub.instance.unread.addListener(_onTick);
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
    SecurityAlertHub.instance.unread.removeListener(_onTick);
    TripCountdownStore.instance.tick.removeListener(_onTick);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    TripCountdownStore.instance.tick.value;
    final items = SecurityAlertHub.instance.all;
    final store = TripCountdownStore.instance;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Trip safety & alerts',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
        actions: [
          if (items.any((a) => !a.read))
            TextButton(
              onPressed: () => SecurityAlertHub.instance.markAllRead(),
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          const InfoNote(
            text:
                'Rider phone: live countdown, GPS safety, and payment alerts appear here. EVUDDY admin CRM, fleet map, and finance desks stay on evuddy.com — not on riders’ phones.',
          ),
          const SizedBox(height: 12),
          if (store.active) _SirenTimerCard(pulse: _pulse),
          if (RiderSafetyTracker.instance.active) ...[
            const SizedBox(height: 10),
            SurfaceCard(
              child: Row(
                children: [
                  const Icon(Icons.my_location_rounded, color: Evuddy.greenDeep),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Phone GPS is streaming to EVUDDY ops for this ride. IoT scooter GPS will appear on admin CRM when devices are live.',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text('INBOX', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 10),
          if (items.isEmpty)
            Text(
              'Start a booking or pay on Razorpay to see reminders and receipt alerts here.',
              style: GoogleFonts.plusJakartaSans(color: Evuddy.muted, fontWeight: FontWeight.w600),
            )
          else
            for (final a in items) ...[
              _AlertTile(alert: a),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}

class _SirenTimerCard extends StatelessWidget {
  const _SirenTimerCard({required this.pulse});
  final AnimationController pulse;

  @override
  Widget build(BuildContext context) {
    final store = TripCountdownStore.instance;
    final untilEnd = store.timeUntilEnd ?? Duration.zero;
    final untilReminder = store.timeUntilReminder ?? Duration.zero;
    final urgent = untilEnd <= const Duration(hours: 1);
    return ScaleTransition(
      scale: Tween<double>(begin: 0.97, end: 1.03).animate(
        CurvedAnimation(parent: pulse, curve: Curves.easeInOut),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: urgent
                ? [const Color(0xFF450A0A), const Color(0xFFDC2626), const Color(0xFFFBBF24)]
                : [const Color(0xFF172554), const Color(0xFF1D4ED8)],
          ),
          boxShadow: [
            BoxShadow(
              color: (urgent ? Evuddy.magenta : Evuddy.greenDeep).withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  urgent ? Icons.emergency_rounded : Icons.timer_rounded,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: 8),
                Text(
                  urgent ? 'SIREN · PLAN ENDING' : 'ACTIVE TRIP TIMER',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              TripCountdownStore.formatDuration(untilEnd),
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 40,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
            Text(
              'until booking ${store.bookingId} ends',
              style: GoogleFonts.plusJakartaSans(color: Colors.white70, fontWeight: FontWeight.w600),
            ),
            if (untilReminder > Duration.zero) ...[
              const SizedBox(height: 10),
              Text(
                '1-hour alert fires in ${TripCountdownStore.formatDuration(untilReminder)}',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  const _AlertTile({required this.alert});
  final SecurityAlert alert;

  @override
  Widget build(BuildContext context) {
    final a = alert;
    return Material(
      color: a.read ? Colors.white : const Color(0xFFFFF8DC),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => SecurityAlertHub.instance.markRead(a.id),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: a.security ? Evuddy.magenta.withValues(alpha: 0.35) : Evuddy.line,
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                a.security ? Icons.campaign_outlined : Icons.notifications_active_outlined,
                color: a.security ? Evuddy.magenta : Evuddy.greenDeep,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a.title,
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      a.body,
                      style: GoogleFonts.plusJakartaSans(
                        color: Evuddy.muted,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SecurityAlertBanner extends StatelessWidget {
  const SecurityAlertBanner({super.key, required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: SecurityAlertHub.instance.unread,
      builder: (context, count, _) {
        if (count <= 0) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Material(
            color: Evuddy.ink,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: onOpen,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.notifications_active_rounded, color: Evuddy.rapidoYellow),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '$count trip alert${count == 1 ? '' : 's'}',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: Colors.white70),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
