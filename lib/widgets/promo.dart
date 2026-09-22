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
      (Icons.https_rounded, 'HTTPS'),
      (Icons.headset_mic_outlined, '24×7'),
    ];
    return Row(
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
    );
  }
}
