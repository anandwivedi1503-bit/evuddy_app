import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/evuddy.dart';

class EvuddyHeader extends StatelessWidget {
  const EvuddyHeader({
    super.key,
    this.onBack,
    this.trailing,
    this.showLogo = true,
  });

  final VoidCallback? onBack;
  final Widget? trailing;
  final bool showLogo;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _IconBtn(
          icon: Icons.arrow_back_rounded,
          onTap: onBack ??
              () {
                if (Navigator.canPop(context)) Navigator.pop(context);
              },
        ),
        Expanded(
          child: showLogo
              ? Center(
                  child: Image.asset(
                    'assets/images/evuddy_logo.png',
                    height: 28,
                    fit: BoxFit.contain,
                  ),
                )
              : const SizedBox.shrink(),
        ),
        trailing ?? const SizedBox(width: 44),
      ],
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Ink(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
          color: Evuddy.wash,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: Evuddy.ink),
      ),
    );
  }
}

class WelcomeRule extends StatelessWidget {
  const WelcomeRule({super.key, this.caption = 'EVUDDY'});

  final String caption;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 28, height: 3, color: Evuddy.green),
        const SizedBox(width: 10),
        Text(
          caption.toUpperCase(),
          style: GoogleFonts.manrope(
            fontSize: 11,
            letterSpacing: 2.4,
            fontWeight: FontWeight.w700,
            color: Evuddy.ink,
          ),
        ),
      ],
    );
  }
}

class StepChip extends StatelessWidget {
  const StepChip({super.key, required this.step, required this.of});
  final int step;
  final int of;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      child: Text(
        '$step / $of',
        textAlign: TextAlign.right,
        style: GoogleFonts.manrope(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Evuddy.muted,
        ),
      ),
    );
  }
}

class EvuddyField extends StatelessWidget {
  const EvuddyField({
    super.key,
    required this.label,
    required this.hint,
    this.controller,
    this.keyboardType,
    this.maxLength,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
  });

  final String label;
  final String hint;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLength: maxLength,
            inputFormatters: inputFormatters,
          textCapitalization: textCapitalization,
          cursorColor: Evuddy.green,
          decoration: InputDecoration(
            counterText: '',
            hintText: hint,
            hintStyle: GoogleFonts.manrope(color: const Color(0xFFB0B0B0), fontSize: 16),
            filled: true,
            fillColor: Evuddy.wash,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Evuddy.black, width: 1.4),
            ),
          ),
          style: GoogleFonts.manrope(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Evuddy.ink,
          ),
        ),
      ],
    );
  }
}

class EvuddyButton extends StatelessWidget {
  const EvuddyButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.arrow_forward_rounded,
    this.dark = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData icon;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: dark ? Evuddy.black : Evuddy.green,
          disabledBackgroundColor: const Color(0xFFD9D9D9),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: enabled ? Colors.white : const Color(0xFF8A8A8A),
              ),
            ),
            const SizedBox(width: 8),
            Icon(icon, size: 18),
          ],
        ),
      ),
    );
  }
}

class InfoNote extends StatelessWidget {
  const InfoNote({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Evuddy.wash,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6),
            decoration: const BoxDecoration(
              color: Evuddy.green,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.manrope(
                color: Evuddy.ink,
                fontWeight: FontWeight.w500,
                height: 1.4,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

PageRouteBuilder<T> evuddyRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, __, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.03),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}
