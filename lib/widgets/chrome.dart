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
    this.showBack = true,
  });

  final VoidCallback? onBack;
  final Widget? trailing;
  final bool showLogo;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Row(
        children: [
          if (showBack)
            _IconBtn(
              icon: Icons.arrow_back_rounded,
              onTap: onBack ??
                  () {
                    if (Navigator.canPop(context)) Navigator.pop(context);
                  },
            )
          else
            const SizedBox(width: 44),
          Expanded(
            child: showLogo
                ? const Center(child: EvuddyLogo(height: 34))
                : const SizedBox.shrink(),
          ),
          trailing ?? const SizedBox(width: 44),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Evuddy.paper,
      shape: const CircleBorder(),
      elevation: 0,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Ink(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Evuddy.paper,
            border: Border.all(color: Evuddy.line),
          ),
          child: Icon(icon, size: 20, color: Evuddy.ink),
        ),
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
        Container(
          width: 36,
          height: 3,
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(99)),
            gradient: LinearGradient(
              colors: [Evuddy.logoGreen, Evuddy.logoPink],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          caption.toUpperCase(),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            letterSpacing: 1.8,
            fontWeight: FontWeight.w700,
            color: Evuddy.muted,
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
    return Text(
      '$step / $of',
      textAlign: TextAlign.right,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Evuddy.muted,
      ),
    );
  }
}

class EvuddyField extends StatefulWidget {
  const EvuddyField({
    super.key,
    required this.label,
    required this.hint,
    this.controller,
    this.keyboardType,
    this.maxLength,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.prefix,
  });

  final String label;
  final String hint;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final Widget? prefix;

  @override
  State<EvuddyField> createState() => _EvuddyFieldState();
}

class _EvuddyFieldState extends State<EvuddyField> {
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _focus = FocusNode()..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final focused = _focus.hasFocus;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: Evuddy.paper,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: focused ? Evuddy.green : Evuddy.line,
              width: focused ? 1.6 : 1,
            ),
            boxShadow: focused
                ? [
                    BoxShadow(
                      color: Evuddy.green.withOpacity(0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [
                    const BoxShadow(
                      color: Color(0x0A0F172A),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            children: [
              if (widget.prefix != null) widget.prefix!,
              Expanded(
                child: TextField(
                  focusNode: _focus,
                  controller: widget.controller,
                  keyboardType: widget.keyboardType,
                  maxLength: widget.maxLength,
                  inputFormatters: widget.inputFormatters,
                  textCapitalization: widget.textCapitalization,
                  cursorColor: Evuddy.magenta,
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: widget.hint,
                    hintStyle: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF94A3B8),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 18,
                    ),
                  ),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Evuddy.ink,
                  ),
                ),
              ),
            ],
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
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: dark
                ? const [Color(0xFF16A34A), Color(0xFF15803D)]
                : const [Evuddy.logoGreen, Evuddy.logoPink],
          ),
          boxShadow: [
            BoxShadow(
              color: Evuddy.green.withOpacity(0.28),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Icon(icon, size: 18),
            ],
          ),
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
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
      decoration: BoxDecoration(
        color: Evuddy.paper,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Evuddy.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 5),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Evuddy.logoGreen, Evuddy.logoPink],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.plusJakartaSans(
                color: Evuddy.ink,
                fontWeight: FontWeight.w500,
                height: 1.45,
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
    transitionDuration: const Duration(milliseconds: 420),
    reverseTransitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, __, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.04, 0),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}
