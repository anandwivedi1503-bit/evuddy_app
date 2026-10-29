import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/security_alert_hub.dart';
import '../services/trip_countdown_store.dart';
import '../state/registration_draft.dart';
import '../theme/evuddy.dart';

class TrustStrip extends StatelessWidget {
  const TrustStrip({super.key});

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.gps_fixed_rounded, 'GPS'),
      (Icons.lock_outline_rounded, 'Hub OTP'),
      (Icons.credit_card_rounded, 'Razorpay'),
      (Icons.headset_mic_outlined, '24×7'),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Evuddy.paper,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Evuddy.line),
      ),
      child: Row(
        children: [
          for (final item in items)
            Expanded(
              child: Column(
                children: [
                  Icon(item.$1, size: 20, color: Evuddy.greenDeep),
                  const SizedBox(height: 6),
                  Text(
                    item.$2,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Evuddy.muted,
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

class QuickActions extends StatefulWidget {
  const QuickActions({
    super.key,
    required this.onAlerts,
    required this.onRegister,
    required this.onInvest,
    required this.onHelp,
    required this.registerLabel,
  });

  final VoidCallback onAlerts;
  final VoidCallback onRegister;
  final VoidCallback onInvest;
  final VoidCallback onHelp;
  final String registerLabel;

  @override
  State<QuickActions> createState() => _QuickActionsState();
}

class _QuickActionsState extends State<QuickActions> with SingleTickerProviderStateMixin {
  late final AnimationController _blink;

  @override
  void initState() {
    super.initState();
    _blink = AnimationController(vsync: this, duration: const Duration(milliseconds: 750))
      ..repeat(reverse: true);
    SecurityAlertHub.instance.unread.addListener(_tick);
    TripCountdownStore.instance.tick.addListener(_tick);
    riderSessionTick.addListener(_tick);
  }

  void _tick() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    SecurityAlertHub.instance.unread.removeListener(_tick);
    TripCountdownStore.instance.tick.removeListener(_tick);
    riderSessionTick.removeListener(_tick);
    _blink.dispose();
    super.dispose();
  }

  bool get _alertLive {
    if (!registrationDraft.phoneVerified) return false;
    return TripCountdownStore.instance.active || SecurityAlertHub.instance.unread.value > 0;
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.emergency_outlined, 'Trip alerts', widget.onAlerts, Evuddy.magenta, true),
      (Icons.badge_outlined, widget.registerLabel, widget.onRegister, Evuddy.greenDeep, false),
      (Icons.trending_up_rounded, 'Calculator', widget.onInvest, Evuddy.magenta, false),
      (Icons.phone_in_talk_outlined, 'Helpdesk', widget.onHelp, const Color(0xFF0F766E), false),
    ];
    return Row(
      children: [
        for (final item in items)
          Expanded(
            child: GestureDetector(
              onTap: item.$3,
              child: Column(
                children: [
                  FadeTransition(
                    opacity: item.$5 && _alertLive
                        ? Tween<double>(begin: 0.45, end: 1).animate(
                            CurvedAnimation(parent: _blink, curve: Curves.easeInOut),
                          )
                        : const AlwaysStoppedAnimation(1),
                    child: Container(
                      height: 58,
                      width: 58,
                      decoration: BoxDecoration(
                        color: item.$4.withValues(alpha: item.$5 && _alertLive ? 0.22 : 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: item.$4.withValues(alpha: item.$5 && _alertLive ? 0.55 : 0.22),
                          width: item.$5 && _alertLive ? 2 : 1,
                        ),
                      ),
                      child: Icon(item.$1, color: item.$4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.$2,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
