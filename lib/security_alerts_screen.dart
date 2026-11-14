import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'services/security_alert_hub.dart';
import 'services/trip_countdown_store.dart';
import 'theme/evuddy.dart';

class SecurityAlertsScreen extends StatefulWidget {
  const SecurityAlertsScreen({super.key});

  @override
  State<SecurityAlertsScreen> createState() => _SecurityAlertsScreenState();
}

class _SecurityAlertsScreenState extends State<SecurityAlertsScreen> {
  Timer? _clock;

  @override
  void initState() {
    super.initState();
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
          if (store.active) const _SirenTimerCard(),
          const SizedBox(height: 16),
          Text('INBOX', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 10),
          if (items.isEmpty)
            Text(
              'Nothing here yet. A reminder appears in the last hour of a ride that has already started.',
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
  const _SirenTimerCard();

  @override
  Widget build(BuildContext context) {
    final store = TripCountdownStore.instance;
    final untilEnd = store.timeUntilEnd ?? Duration.zero;
    final urgent = untilEnd <= const Duration(hours: 1);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: urgent ? const Color(0xFF7F1D1D) : const Color(0xFF172554),
      ),
      child: Row(
        children: [
          Icon(
            urgent ? Icons.notifications_active_rounded : Icons.timer_outlined,
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  urgent ? 'Return soon' : 'Ride time left',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                Text(
                  TripCountdownStore.formatDuration(untilEnd),
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
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
