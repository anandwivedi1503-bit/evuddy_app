import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/evuddy.dart';

/// Rapido-style scooter avatar until real fleet photos are uploaded.
class ScooterAvatar extends StatelessWidget {
  const ScooterAvatar({
    super.key,
    required this.seed,
    this.size = 86,
    this.selected = false,
  });

  final String seed;
  final double size;
  final bool selected;

  static const _glyphs = ['🛵', '🏍️', '⚡', '🛴', '🚲', '🔋'];

  static String emojiFor(String seed) {
    if (seed.isEmpty) return _glyphs.first;
    var h = 0;
    for (final c in seed.codeUnits) {
      h = (h * 31 + c) & 0x7fffffff;
    }
    return _glyphs[h % _glyphs.length];
  }

  static Color tintFor(String seed) {
    if (seed.isEmpty) return Evuddy.rapidoYellow;
    var h = 0;
    for (final c in seed.codeUnits) {
      h = (h * 17 + c) & 0x7fffffff;
    }
    final palette = [
      Evuddy.rapidoYellow,
      const Color(0xFFBBF7D0),
      const Color(0xFFBFDBFE),
      const Color(0xFFFDE68A),
      const Color(0xFFFBCFE8),
    ];
    return palette[h % palette.length];
  }

  @override
  Widget build(BuildContext context) {
    final emoji = emojiFor(seed);
    final bg = selected ? Evuddy.rapidoYellow : tintFor(seed);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Evuddy.ink.withValues(alpha: 0.08)),
      ),
      alignment: Alignment.center,
      child: Text(
        emoji,
        style: TextStyle(fontSize: size * 0.42),
      ),
    );
  }
}
