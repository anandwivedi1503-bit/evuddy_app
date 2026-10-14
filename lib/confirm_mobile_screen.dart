import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'state/registration_draft.dart';
import 'verify_mobile_otp_screen.dart';
import 'widgets/booking_ui.dart';
import 'widgets/chrome.dart';
import 'widgets/voice_fill.dart';

/// Website Book EV: confirm mobile, then OTP. Approved riders skip KYC.
class ConfirmMobileScreen extends StatefulWidget {
  const ConfirmMobileScreen({super.key});

  @override
  State<ConfirmMobileScreen> createState() => _ConfirmMobileScreenState();
}

class _ConfirmMobileScreenState extends State<ConfirmMobileScreen> {
  late final TextEditingController phone;
  String? error;
  bool _openedOtp = false;

  @override
  void initState() {
    super.initState();
    phone = TextEditingController(text: registrationDraft.phone);
    if (registrationDraft.otpGate == 'book' &&
        registrationDraft.phoneVerified &&
        registrationDraft.phone.length == 10) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_openedOtp) _send();
      });
    }
  }

  @override
  void dispose() {
    phone.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final p = phone.text.replaceAll(RegExp(r'\D'), '');
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(p)) {
      setState(() => error = 'Enter a valid 10-digit Indian mobile number.');
      return;
    }
    if (registrationDraft.phone != p) {
      registrationDraft.resetProfileForNewPhone();
    }
    registrationDraft
      ..phone = p
      ..otpGate = 'book';
    await registrationDraft.persist();
    if (!mounted) return;
    _openedOtp = true;
    Navigator.push(context, evuddyRoute(const VerifyMobileOtpScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return BookStage(
      showBack: false,
      kicker: 'Book EV',
      title: 'Confirm your mobile',
      step: 1,
      of: 4,
      subtitle: registrationDraft.hasLiveBooking
          ? 'Same registered mobile as this booking. OTP refreshes Firebase so Razorpay can charge remaining.'
          : 'New riders: OTP, then name and email, then KYC. Approved riders skip to scooters.',
      error: error,
      footer: EvuddyButton(sun: true, label: 'Send OTP', onPressed: _send),
      children: [
        FormDeck(
          eyebrow: 'Registered mobile',
          title: 'We’ll text a 6-digit OTP',
          icon: Icons.smartphone_rounded,
          children: [
            EvuddyField(
              label: 'MOBILE NUMBER',
              hint: '10-digit mobile',
              controller: phone,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              prefix: const PhonePrefix(),
              voiceKind: VoiceKind.phone,
            ),
          ],
        ),
      ],
    );
  }
}
