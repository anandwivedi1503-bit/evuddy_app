import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/festive_today.dart';
import '../theme/evuddy.dart';

/// In-flow festival line. It scrolls with the home page.
class FestiveHomeMast extends StatelessWidget {
  const FestiveHomeMast({super.key, required this.today});

  final FestiveToday today;

  @override
  Widget build(BuildContext context) {
    final line = today.ribbon.isEmpty ? today.title : today.ribbon;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: today.accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: today.accent.withValues(alpha: 0.45)),
      ),
      child: Text(
        line,
        style: GoogleFonts.plusJakartaSans(
          color: Evuddy.ink,
          fontWeight: FontWeight.w800,
          fontSize: 13,
          height: 1.35,
        ),
      ),
    );
  }
}

Future<void> showFestivePoster(BuildContext context, FestiveToday today) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      return Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (today.heroUrl.isNotEmpty)
                  AspectRatio(
                    aspectRatio: 16 / 10,
                    child: Image.network(
                      today.heroUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _AccentBand(color: today.accent),
                    ),
                  )
                else
                  _AccentBand(color: today.accent),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        today.title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          height: 1.15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          color: Evuddy.ink,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        today.body,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          height: 1.45,
                          fontWeight: FontWeight.w600,
                          color: Evuddy.muted,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: today.accent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            'Continue',
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
                          ),
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
  );
}

class _AccentBand extends StatelessWidget {
  const _AccentBand({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(height: 88, color: color);
  }
}
