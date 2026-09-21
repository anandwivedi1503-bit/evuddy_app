import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/evuddy.dart';

class EvuddyHeader extends StatelessWidget {
  const EvuddyHeader({
    super.key,
    this.onBack,
    this.trailing,
  });

  final VoidCallback? onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RoundIcon(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: onBack ??
              () {
                if (Navigator.canPop(context)) Navigator.pop(context);
              },
        ),
        Expanded(
          child: Center(
            child: Image.asset(
              'assets/images/evuddy_logo.png',
              height: 44,
              fit: BoxFit.contain,
            ),
          ),
        ),
        trailing ?? const SizedBox(width: 48),
      ],
    );
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Evuddy.paper,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Evuddy.line),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(icon, size: 16, color: Evuddy.ink),
        ),
      ),
    );
  }
}

class WelcomeRule extends StatelessWidget {
  const WelcomeRule({super.key, this.caption = 'WELCOME TO EVUDDY'});

  final String caption;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: Evuddy.line, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            caption,
            style: const TextStyle(
              fontSize: 10,
              letterSpacing: 2.2,
              fontWeight: FontWeight.w700,
              color: Evuddy.gold,
            ),
          ),
        ),
        const Expanded(child: Divider(color: Evuddy.line, thickness: 1)),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Evuddy.paper,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Evuddy.line),
      ),
      child: Text(
        'Step $step of $of',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Evuddy.ink,
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
        Container(
          height: 56,
          decoration: BoxDecoration(
            color: Evuddy.paper,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Evuddy.line),
          ),
          alignment: Alignment.center,
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLength: maxLength,
            inputFormatters: inputFormatters,
            textCapitalization: textCapitalization,
            decoration: InputDecoration(
              counterText: '',
              hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFFA3AA9E), fontSize: 15),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Evuddy.ink,
            ),
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
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Evuddy.green,
          disabledBackgroundColor: Evuddy.line,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 10),
            Icon(icon, size: 20),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Evuddy.greenSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF0A6B30),
          fontWeight: FontWeight.w500,
          height: 1.35,
          fontSize: 13,
        ),
      ),
    );
  }
}

PageRouteBuilder<T> evuddyRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 320),
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
