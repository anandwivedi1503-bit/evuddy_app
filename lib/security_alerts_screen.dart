import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'services/security_alert_hub.dart';
import 'theme/evuddy.dart';

class SecurityAlertsScreen extends StatefulWidget {
  const SecurityAlertsScreen({super.key});

  @override
  State<SecurityAlertsScreen> createState() => _SecurityAlertsScreenState();
}

class _SecurityAlertsScreenState extends State<SecurityAlertsScreen> {
  @override
  void initState() {
    super.initState();
    SecurityAlertHub.instance.unread.addListener(_onTick);
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    SecurityAlertHub.instance.unread.removeListener(_onTick);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = SecurityAlertHub.instance.all;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Alerts',
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
      body: items.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'Trip reminders, payment receipts, and safety messages appear here — like Rapido in-app alerts.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    color: Evuddy.muted,
                    fontWeight: FontWeight.w600,
                    height: 1.45,
                  ),
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final a = items[i];
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
                            a.security ? Icons.shield_outlined : Icons.notifications_active_outlined,
                            color: a.security ? Evuddy.magenta : Evuddy.greenDeep,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  a.title,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
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
              },
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
                        '$count security / trip alert${count == 1 ? '' : 's'}',
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
