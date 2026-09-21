import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'state/registration_draft.dart';
import 'theme/evuddy.dart';
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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Evuddy.cream,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Evuddy.cream,
      ),
      child: Scaffold(
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight - 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const EvuddyHeader(),
                      const SizedBox(height: 28),
                      const WelcomeRule(),
                      const SizedBox(height: 28),
                      Text(
                        'Confirm your\nmobile number',
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Riders already on EVUDDY verify OTP, then book. New riders continue to registration — same KYC the website uses.',
                      ),
                      const SizedBox(height: 32),
                      Text('MOBILE NUMBER', style: Theme.of(context).textTheme.labelSmall),
                      const SizedBox(height: 10),
                      Container(
                        height: 60,
                        decoration: BoxDecoration(
                          color: Evuddy.paper,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Evuddy.line),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 14),
                            Container(
                              width: 36,
                              height: 36,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Evuddy.greenSoft,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text('🇮🇳', style: TextStyle(fontSize: 18)),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              '+91',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: Evuddy.ink,
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 22,
                              margin: const EdgeInsets.symmetric(horizontal: 12),
                              color: Evuddy.line,
                            ),
                            Expanded(
                              child: TextField(
                                controller: phoneController,
                                keyboardType: TextInputType.phone,
                                maxLength: 10,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  counterText: '',
                                  hintText: '10-digit mobile',
                                  hintStyle: TextStyle(color: Color(0xFFA3AA9E)),
                                ),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (error != null) ...[
                        const SizedBox(height: 10),
                        Text(error!, style: const TextStyle(color: Color(0xFFB42318), fontSize: 13)),
                      ],
                      const SizedBox(height: 28),
                      EvuddyButton(label: 'Send OTP', onPressed: _sendOtp),
                      const SizedBox(height: 16),
                      const Center(
                        child: Text(
                          'Your number is used only for rider login and yard OTP.',
                          style: TextStyle(fontSize: 12, color: Evuddy.muted),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
