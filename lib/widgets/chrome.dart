import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/evuddy.dart';
import 'voice_fill.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({
    super.key,
    required this.title,
    required this.children,
    this.kicker = 'EVUDDY',
    this.subtitle,
    this.showBack = true,
    this.footer,
    this.step,
    this.of = 4,
    this.error,
    this.titleStyle,
    this.expanded,
  });

  final String title;
  final String kicker;
  final String? subtitle;
  final bool showBack;
  final List<Widget> children;
  final Widget? footer;
  final int? step;
  final int of;
  final String? error;
  final TextStyle? titleStyle;
  /// Fills leftover height (used so Recaptcha image grids are not clipped).
  final Widget? expanded;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Evuddy.wash,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Evuddy.wash,
        body: ColoredBox(
          color: Evuddy.wash,
          child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 6, 18, 0),
                    child: EvuddyHeader(
                      showBack: showBack,
                      trailing: step == null
                          ? null
                          : StepChip(step: step!, of: of),
                    ),
                  ),
                  Expanded(
                    child: expanded == null
                        ? GestureDetector(
                            onTap: () => FocusScope.of(context).unfocus(),
                            behavior: HitTestBehavior.translucent,
                            child: ListView(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(22, 18, 22, 16),
                              children: [
                                WelcomeRule(caption: kicker),
                                const SizedBox(height: 14),
                                Text(
                                  title,
                                  style: titleStyle ??
                                      Theme.of(context).textTheme.displaySmall,
                                ),
                                if (subtitle != null) ...[
                                  const SizedBox(height: 10),
                                  Text(subtitle!),
                                ],
                                const SizedBox(height: 22),
                                ...children,
                                if (error != null) ...[
                                  const SizedBox(height: 14),
                                  _ErrorBanner(text: error!),
                                ],
                                const SizedBox(height: 8),
                              ],
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(22, 12, 22, 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    WelcomeRule(caption: kicker),
                                    const SizedBox(height: 10),
                                    Text(
                                      title,
                                      style: titleStyle ??
                                          Theme.of(context)
                                              .textTheme
                                              .headlineMedium,
                                    ),
                                    if (subtitle != null) ...[
                                      const SizedBox(height: 8),
                                      Text(subtitle!),
                                    ],
                                    const SizedBox(height: 16),
                                    ...children,
                                    if (error != null) ...[
                                      const SizedBox(height: 10),
                                      _ErrorBanner(text: error!),
                                    ],
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 0, 16, 8),
                                  child: expanded!,
                                ),
                              ),
                            ],
                          ),
                  ),
                  if (footer != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 4, 22, 18),
                      child: footer,
                    ),
                ],
              ),
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
      height: 64,
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
                ? const FittedBox(
                    fit: BoxFit.contain,
                    child: EvuddyLogo(height: 52),
                  )
                : const SizedBox.shrink(),
          ),
          trailing ?? const SizedBox(width: 40),
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
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Ink(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Evuddy.paper,
            border: Border.all(color: Evuddy.line),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A07110C),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
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
          width: 28,
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
            letterSpacing: 1.9,
            fontWeight: FontWeight.w800,
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
    return SizedBox(
      width: 88,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '$step of $of',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Evuddy.muted,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: List.generate(of, (i) {
              final on = i < step;
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  height: 3,
                  margin: EdgeInsets.only(left: i == 0 ? 0 : 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(99),
                    gradient: on
                        ? const LinearGradient(
                            colors: [Evuddy.logoGreen, Evuddy.logoPink],
                          )
                        : null,
                    color: on ? null : Evuddy.line,
                  ),
                ),
              );
            }),
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
    this.voiceKind,
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
  final VoiceKind? voiceKind;

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
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            letterSpacing: 1.3,
            fontWeight: FontWeight.w800,
            color: focused ? Evuddy.greenDeep : Evuddy.muted,
          ),
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: Evuddy.paper,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: focused ? Evuddy.green : Evuddy.line,
              width: focused ? 1.7 : 1,
            ),
            boxShadow: focused
                ? [
                    BoxShadow(
                      color: Evuddy.green.withOpacity(0.16),
                      blurRadius: 22,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : Evuddy.lift,
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
                  cursorColor: Evuddy.magenta,
                  cursorWidth: 2,
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: widget.hint,
                    hintStyle: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF94A3B8),
                      fontSize: 15.5,
                      fontWeight: FontWeight.w500,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 18,
                    ),
                  ),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w600,
                    color: Evuddy.ink,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              if (widget.suffix != null) widget.suffix!,
              if (widget.voiceKind != null && widget.controller != null)
                VoiceMicButton(
                  kind: widget.voiceKind!,
                  onResult: (v) {
                    if (v.isEmpty) return;
                    widget.controller!.text = v;
                    widget.controller!.selection = TextSelection.collapsed(offset: v.length);
                  },
                ),
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
      padding: const EdgeInsets.only(left: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Evuddy.greenSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '🇮🇳  +91',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: Evuddy.greenDeep,
              ),
            ),
          ),
          Container(
            width: 1,
            height: 22,
            margin: const EdgeInsets.symmetric(horizontal: 10),
            color: Evuddy.line,
          ),
        ],
      ),
    );
  }
}

class EvuddyButton extends StatefulWidget {
  const EvuddyButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.arrow_forward_rounded,
    this.dark = true,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData icon;
  final bool dark;
  final bool busy;

  @override
  State<EvuddyButton> createState() => _EvuddyButtonState();
}

class _EvuddyButtonState extends State<EvuddyButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _down ? 0.98 : 1,
      duration: const Duration(milliseconds: 120),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.dark
                  ? const [Color(0xFF16A34A), Color(0xFF047857)]
                  : const [Evuddy.logoGreen, Evuddy.logoPink],
            ),
            boxShadow: [
              BoxShadow(
                color: Evuddy.green.withOpacity(0.32),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onHighlightChanged: (v) => setState(() => _down = v),
              onTap: widget.busy || widget.onPressed == null
                  ? null
                  : () {
                      HapticFeedback.lightImpact();
                      widget.onPressed!();
                    },
              child: Center(
                child: widget.busy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            widget.label,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(widget.icon, size: 18, color: Colors.white),
                        ],
                      ),
              ),
            ),
          ),
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
      height: 56,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: Evuddy.ink,
          side: const BorderSide(color: Evuddy.line),
          backgroundColor: Evuddy.paper,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
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
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Evuddy.paper.withOpacity(0.78),
        borderRadius: BorderRadius.circular(16),
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

class SurfaceCard extends StatelessWidget {
  const SurfaceCard({super.key, required this.child, this.padding});
  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Evuddy.paper,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Evuddy.line),
        boxShadow: Evuddy.lift,
      ),
      child: child,
    );
  }
}

class OtpPinField extends StatefulWidget {
  const OtpPinField({
    super.key,
    required this.controller,
    this.onCompleted,
    this.autofocus = true,
  });

  final TextEditingController controller;
  final ValueChanged<String>? onCompleted;
  final bool autofocus;

  @override
  State<OtpPinField> createState() => _OtpPinFieldState();
}

class _OtpPinFieldState extends State<OtpPinField> {
  final focus = FocusNode();
  bool _fired = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onText);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onText);
    focus.dispose();
    super.dispose();
  }

  void _onText() {
    final digits = widget.controller.text.replaceAll(RegExp(r'\D'), '');
    if (digits != widget.controller.text) {
      widget.controller.value = TextEditingValue(
        text: digits.length > 6 ? digits.substring(0, 6) : digits,
        selection: TextSelection.collapsed(
          offset: (digits.length > 6 ? 6 : digits.length),
        ),
      );
      return;
    }
    setState(() {});
    if (digits.length == 6 && !_fired) {
      _fired = true;
      widget.onCompleted?.call(digits);
      TextInput.finishAutofillContext();
    }
    if (digits.length < 6) _fired = false;
  }

  @override
  Widget build(BuildContext context) {
    final code = widget.controller.text;
    return AutofillGroup(
      child: GestureDetector(
        onTap: () => focus.requestFocus(),
        child: Stack(
          children: [
            Opacity(
              opacity: 0.02,
              child: TextField(
                controller: widget.controller,
                focusNode: focus,
                autofocus: widget.autofocus,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.oneTimeCode],
                enableSuggestions: false,
                autocorrect: false,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  counterText: '',
                  border: InputBorder.none,
                ),
                style: const TextStyle(color: Colors.transparent, fontSize: 1),
                cursorColor: Colors.transparent,
              ),
            ),
            Row(
              children: List.generate(6, (i) {
                final filled = i < code.length;
                final current = i == code.length;
                return Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    margin: EdgeInsets.only(right: i == 5 ? 0 : 7),
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Evuddy.paper,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: current
                            ? Evuddy.green
                            : filled
                                ? Evuddy.logoGreen
                                : Evuddy.line,
                        width: current || filled ? 1.7 : 1,
                      ),
                    ),
                    child: Text(
                      filled ? code[i] : '',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Evuddy.ink,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
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
            duration: const Duration(milliseconds: 180),
            margin: EdgeInsets.only(right: i == widget.controllers.length - 1 ? 0 : 7),
            height: 58,
            decoration: BoxDecoration(
              color: Evuddy.paper,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: focused
                    ? Evuddy.green
                    : filled
                        ? Evuddy.logoGreen
                        : Evuddy.line,
                width: focused || filled ? 1.7 : 1,
              ),
              boxShadow: focused
                  ? [
                      BoxShadow(
                        color: Evuddy.green.withOpacity(0.16),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : Evuddy.lift,
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
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w800,
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

class ChoicePills extends StatelessWidget {
  const ChoicePills({
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
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((o) {
        final sel = o == value;
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onChanged(o);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: sel ? Evuddy.greenSoft : Evuddy.paper,
              borderRadius: BorderRadius.circular(99),
              border: Border.all(
                color: sel ? Evuddy.green : Evuddy.line,
                width: sel ? 1.4 : 1,
              ),
              boxShadow: sel ? Evuddy.lift : null,
            ),
            child: Text(
              o,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: sel ? Evuddy.greenDeep : Evuddy.ink,
              ),
            ),
          ),
        );
      }).toList(),
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: selected ? Evuddy.greenSoft : Evuddy.paper,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? Evuddy.green : Evuddy.line,
                width: selected ? 1.6 : 1,
              ),
              boxShadow: Evuddy.lift,
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: selected
                        ? const LinearGradient(
                            colors: [Evuddy.logoGreen, Evuddy.greenDeep],
                          )
                        : null,
                    color: selected ? null : const Color(0xFFF8FAFC),
                    border: selected ? null : Border.all(color: Evuddy.line),
                  ),
                  child: Icon(
                    selected ? Icons.check_rounded : icon,
                    color: selected ? Colors.white : Evuddy.muted,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: Evuddy.ink,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        selected ? 'Attached on this device' : subtitle,
                        style: GoogleFonts.plusJakartaSans(
                          color: selected ? Evuddy.greenDeep : Evuddy.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  selected ? Icons.verified_rounded : Icons.add_rounded,
                  color: selected ? Evuddy.green : Evuddy.muted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          color: Evuddy.danger,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

PageRouteBuilder<T> evuddyRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 520),
    reverseTransitionDuration: const Duration(milliseconds: 320),
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, __, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.035),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}
