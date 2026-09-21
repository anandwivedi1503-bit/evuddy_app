import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/evuddy.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
    this.showBack = true,
    this.footer,
    this.step,
    this.of = 4,
    this.error,
  });

  final String title;
  final String? subtitle;
  final bool showBack;
  final List<Widget> children;
  final Widget? footer;
  final int? step;
  final int of;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              if (step != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: step! / of,
                    child: Container(height: 3, color: Evuddy.green),
                  ),
                )
              else
                const SizedBox(height: 3),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
                child: EvuddyHeader(showBack: showBack, step: step, of: of),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => FocusScope.of(context).unfocus(),
                  behavior: HitTestBehavior.translucent,
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                    children: [
                      Text(title, style: Theme.of(context).textTheme.displaySmall),
                      if (subtitle != null) ...[
                        const SizedBox(height: 8),
                        Text(subtitle!),
                      ],
                      const SizedBox(height: 28),
                      ...children,
                      if (error != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          error!,
                          style: GoogleFonts.inter(
                            color: Evuddy.danger,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (footer != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                  child: footer,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class EvuddyHeader extends StatelessWidget {
  const EvuddyHeader({
    super.key,
    this.onBack,
    this.showBack = true,
    this.step,
    this.of = 4,
  });

  final VoidCallback? onBack;
  final bool showBack;
  final int? step;
  final int of;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          if (showBack)
            IconButton(
              onPressed: onBack ??
                  () {
                    if (Navigator.canPop(context)) Navigator.pop(context);
                  },
              icon: const Icon(Icons.arrow_back_rounded, color: Evuddy.ink),
            )
          else
            const SizedBox(width: 12),
          const EvuddyMark(size: 20),
          const Spacer(),
          if (step != null)
            Text(
              '$step of $of',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Evuddy.muted,
              ),
            ),
        ],
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
    this.suffix,
    this.readOnly = false,
    this.onTap,
  });

  final String label;
  final String hint;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final Widget? prefix;
  final Widget? suffix;
  final bool readOnly;
  final VoidCallback? onTap;

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
        Text(
          widget.label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Evuddy.ink,
          ),
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          decoration: BoxDecoration(
            color: Evuddy.field,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: focused ? Evuddy.ink : Colors.transparent,
              width: 1.4,
            ),
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
                  readOnly: widget.readOnly,
                  onTap: widget.onTap,
                  cursorColor: Evuddy.green,
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: widget.hint,
                    hintStyle: GoogleFonts.inter(
                      color: const Color(0xFF9CA3AF),
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Evuddy.ink,
                  ),
                ),
              ),
              if (widget.suffix != null) widget.suffix!,
            ],
          ),
        ),
      ],
    );
  }
}

class PhonePrefix extends StatelessWidget {
  const PhonePrefix({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '+91',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Evuddy.ink,
            ),
          ),
          Container(
            width: 1,
            height: 18,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            color: Evuddy.line,
          ),
        ],
      ),
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
      height: 54,
      child: ElevatedButton(
        onPressed: onPressed == null
            ? null
            : () {
                HapticFeedback.lightImpact();
                onPressed!();
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: Evuddy.ink,
          disabledBackgroundColor: const Color(0xFFD4D4D8),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 8),
            Icon(icon, size: 18),
          ],
        ),
      ),
    );
  }
}

class EvuddyGhostButton extends StatelessWidget {
  const EvuddyGhostButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: Evuddy.ink,
          side: const BorderSide(color: Evuddy.line),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
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
    return Text(
      text,
      style: GoogleFonts.inter(
        color: Evuddy.muted,
        fontSize: 13,
        height: 1.4,
      ),
    );
  }
}

class OtpRow extends StatefulWidget {
  const OtpRow({super.key, required this.controllers, required this.foci});
  final List<TextEditingController> controllers;
  final List<FocusNode> foci;

  @override
  State<OtpRow> createState() => _OtpRowState();
}

class _OtpRowState extends State<OtpRow> {
  @override
  void initState() {
    super.initState();
    for (final f in widget.foci) {
      f.addListener(() => setState(() {}));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(widget.controllers.length, (i) {
        final filled = widget.controllers[i].text.isNotEmpty;
        final focused = widget.foci[i].hasFocus;
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: EdgeInsets.only(right: i == widget.controllers.length - 1 ? 0 : 8),
            height: 56,
            decoration: BoxDecoration(
              color: Evuddy.field,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: focused
                    ? Evuddy.ink
                    : filled
                        ? Evuddy.green
                        : Colors.transparent,
                width: 1.4,
              ),
            ),
            child: TextField(
              controller: widget.controllers[i],
              focusNode: widget.foci[i],
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              maxLength: 1,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                counterText: '',
                border: InputBorder.none,
              ),
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Evuddy.ink,
              ),
              onChanged: (v) {
                setState(() {});
                if (v.isNotEmpty && i < widget.controllers.length - 1) {
                  widget.foci[i + 1].requestFocus();
                }
                if (v.isEmpty && i > 0) widget.foci[i - 1].requestFocus();
              },
            ),
          ),
        );
      }),
    );
  }
}

class SelectList extends StatelessWidget {
  const SelectList({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final List<String> options;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Evuddy.field,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          for (var i = 0; i < options.length; i++) ...[
            InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                onChanged(options[i]);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                child: Row(
                  children: [
                    Icon(
                      options[i] == value
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_off_rounded,
                      size: 20,
                      color: options[i] == value ? Evuddy.green : Evuddy.muted,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        options[i],
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: options[i] == value
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: Evuddy.ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (i != options.length - 1)
              const Divider(height: 1, indent: 44, color: Evuddy.line),
          ],
        ],
      ),
    );
  }
}

class DocTile extends StatelessWidget {
  const DocTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.icon = Icons.photo_outlined,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Evuddy.field,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? Evuddy.green : Colors.transparent,
              width: 1.4,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: selected ? Evuddy.green : Evuddy.muted),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Evuddy.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      selected ? 'Attached' : subtitle,
                      style: GoogleFonts.inter(
                        color: selected ? Evuddy.green : Evuddy.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
                color: selected ? Evuddy.green : Evuddy.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

PageRouteBuilder<T> evuddyRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, __, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOut);
      return FadeTransition(opacity: curved, child: child);
    },
  );
}
