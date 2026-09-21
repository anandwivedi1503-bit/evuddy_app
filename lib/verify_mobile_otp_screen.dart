import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'personal_information_screen.dart';
import 'state/registration_draft.dart';
import 'theme/evuddy.dart';
import 'widgets/chrome.dart';

class VerifyMobileOtpScreen extends StatefulWidget {
  const VerifyMobileOtpScreen({super.key});

  @override
  State<VerifyMobileOtpScreen> createState() => _VerifyMobileOtpScreenState();
}

class _VerifyMobileOtpScreenState extends State<VerifyMobileOtpScreen> {
  final boxes = List.generate(6, (_) => TextEditingController());
  final foci = List.generate(6, (_) => FocusNode());
  int seconds = 45;
  Timer? timer;
  String? error;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (seconds == 0) return;
      setState(() => seconds -= 1);
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    for (final c in boxes) {
      c.dispose();
    }
    for (final f in foci) {
      f.dispose();
    }
    super.dispose();
  }

  String get code => boxes.map((c) => c.text).join();

  void _verify() {
    if (code.length != 6) {
      setState(() => error = 'Enter the 6-digit OTP.');
      return;
    }
    registrationDraft.phoneVerified = true;
    Navigator.push(context, evuddyRoute(const PersonalInformationScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final phone = registrationDraft.phoneDisplay;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EvuddyHeader(
                trailing: const StepChip(step: 1, of: 4),
              ),
              const SizedBox(height: 24),
              const WelcomeRule(caption: 'SECURE SIGN IN'),
              const SizedBox(height: 24),
              Text('Enter your OTP', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              const Text('A 6-digit code is sent to your mobile. SMS is not live yet — any 6 digits continue this frontend.'),
              const SizedBox(height: 22),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Evuddy.paper,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Evuddy.line),
                ),
                child: Row(
                  children: [
                    const Text('🇮🇳', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),
                    Text(
                      phone.isEmpty ? '+91' : phone,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text(
                        'Change',
                        style: TextStyle(
                          color: Evuddy.green,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('ENTER 6-DIGIT OTP', style: Theme.of(context).textTheme.labelSmall),
                  const Text(
                    'Auto-read later',
                    style: TextStyle(color: Evuddy.green, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: List.generate(6, (i) {
                  return Expanded(
                    child: Container(
                      margin: EdgeInsets.only(right: i == 5 ? 0 : 6),
                      height: 54,
                      decoration: BoxDecoration(
                        color: Evuddy.paper,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Evuddy.line),
                      ),
                      child: TextField(
                        controller: boxes[i],
                        focusNode: foci[i],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(
                          counterText: '',
                          border: InputBorder.none,
                        ),
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                        onChanged: (v) {
                          if (v.isNotEmpty && i < 5) foci[i + 1].requestFocus();
                          if (v.isEmpty && i > 0) foci[i - 1].requestFocus();
                        },
                      ),
                    ),
                  );
                }),
              ),
              if (error != null) ...[
                const SizedBox(height: 10),
                Text(error!, style: const TextStyle(color: Color(0xFFB42318), fontSize: 13)),
              ],
              const SizedBox(height: 16),
              InfoNote(text: 'OTP will be sent to ${phone.isEmpty ? "your number" : phone} when backend is connected.'),
              const SizedBox(height: 22),
              Center(
                child: Text(
                  seconds > 0 ? "Didn't receive code?  00:${seconds.toString().padLeft(2, '0')}" : 'You can resend the code.',
                  style: const TextStyle(color: Evuddy.muted, fontSize: 14),
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: seconds == 0
                          ? () => setState(() => seconds = 45)
                          : null,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        side: const BorderSide(color: Evuddy.line),
                        foregroundColor: Evuddy.ink,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Resend'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: EvuddyButton(label: 'Verify OTP', onPressed: _verify),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
