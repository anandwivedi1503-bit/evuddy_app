import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'state/registration_draft.dart';
import 'theme/evuddy.dart';
import 'verify_mobile_otp_screen.dart';
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

  @override
  void initState() {
    super.initState();
    phone = TextEditingController(text: registrationDraft.phone);
  }

  @override
  void dispose() {
    phone.dispose();
    super.dispose();
  }

  void _send() {
    final p = phone.text.replaceAll(RegExp(r'\D'), '');
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(p)) {
      setState(() => error = 'Enter a valid 10-digit Indian mobile number.');
      return;
    }
    registrationDraft
      ..phone = p
      ..otpGate = 'book';
    Navigator.push(context, evuddyRoute(const VerifyMobileOtpScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return AuthScreen(
      showBack: false,
      kicker: 'Book EV',
      title: 'Confirm your\nmobile number',
      subtitle:
          'Same as the website. If this number is already approved, you go straight to rental vs Rent to Own.',
      error: error,
      footer: EvuddyButton(label: 'Send OTP', onPressed: _send),
      children: [
        const ScenePhoto(asset: Evuddy.yellowScooterAsset, height: 200, fit: BoxFit.contain),
        const SizedBox(height: 18),
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
    );
  }
}
