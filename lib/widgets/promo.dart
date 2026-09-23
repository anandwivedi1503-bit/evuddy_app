import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/evuddy.dart';

class TrustStrip extends StatelessWidget {
  const TrustStrip({super.key});

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.verified_user_outlined, 'KYC'),
      (Icons.lock_outline_rounded, 'Hub OTP'),
      (Icons.verified_outlined, 'Secure pay'),
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

class QuickActions extends StatelessWidget {
  const QuickActions({
    super.key,
    required this.onBook,
    required this.onRegister,
    required this.onInvest,
    required this.onHelp,
    required this.registerLabel,
  });

  final VoidCallback onBook;
  final VoidCallback onRegister;
  final VoidCallback onInvest;
  final VoidCallback onHelp;
  final String registerLabel;

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.electric_moped_rounded, 'Book EV', onBook, Evuddy.green),
      (Icons.badge_outlined, registerLabel, onRegister, Evuddy.greenDeep),
      (Icons.trending_up_rounded, 'Invest', onInvest, Evuddy.magenta),
      (Icons.phone_in_talk_outlined, 'Helpdesk', onHelp, const Color(0xFF0F766E)),
    ];
    return Row(
      children: [
        for (final item in items)
          Expanded(
            child: GestureDetector(
              onTap: item.$3,
              child: Column(
                children: [
                  Container(
                    height: 58,
                    width: 58,
                    decoration: BoxDecoration(
                      color: item.$4.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(color: item.$4.withValues(alpha: 0.22)),
                    ),
                    child: Icon(item.$1, color: item.$4),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.$2,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
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
