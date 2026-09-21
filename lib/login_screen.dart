import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'state/registration_draft.dart';
import 'verify_mobile_otp_screen.dart';
import 'widgets/chrome.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final TextEditingController phoneController;
  String? error;

  @override
  void initState() {
    super.initState();
    phoneController = TextEditingController(text: registrationDraft.phone);
  }

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  void _sendOtp() {
    FocusScope.of(context).unfocus();
    final phone = phoneController.text.replaceAll(RegExp(r'\D'), '');
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(phone)) {
      setState(() => error = 'Enter a valid 10-digit Indian mobile number.');
      return;
    }
    registrationDraft.phone = phone;
    registrationDraft.phoneVerified = false;
    Navigator.push(context, evuddyRoute(const VerifyMobileOtpScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return AuthScreen(
      showBack: false,
      title: 'Enter your\nmobile number',
      subtitle: 'We’ll send a 6-digit code. New riders continue to KYC after this.',
      error: error,
      footer: EvuddyButton(label: 'Continue', onPressed: _sendOtp),
      children: [
        EvuddyField(
          label: 'Mobile number',
          hint: '98765 43210',
          controller: phoneController,
          keyboardType: TextInputType.phone,
          maxLength: 10,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          prefix: const PhonePrefix(),
        ),
      ],
    );
  }
}
