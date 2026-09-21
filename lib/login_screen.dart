import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

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
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Evuddy.wash,
      ),
      child: Scaffold(
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight - 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const EvuddyHeader(showBack: false),
                      const SizedBox(height: 36),
                      const WelcomeRule(caption: 'Sign in'),
                      const SizedBox(height: 16),
                      Text(
                        'Your number,\nyour ride.',
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Riders already on EVUDDY verify OTP, then book. New riders continue to registration — same KYC the website uses.',
                      ),
                      const SizedBox(height: 32),
                      EvuddyField(
                        label: 'MOBILE NUMBER',
                        hint: '10-digit mobile',
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        prefix: Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '+91',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 22,
                                margin: const EdgeInsets.symmetric(horizontal: 12),
                                color: Evuddy.line,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (error != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          error!,
                          style: const TextStyle(color: Color(0xFFB42318), fontSize: 13),
                        ),
                      ],
                      const SizedBox(height: 28),
                      EvuddyButton(label: 'Send OTP', onPressed: _sendOtp),
                      const SizedBox(height: 16),
                      const Center(
                        child: Text(
                          'Used only for rider login and yard OTP.',
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
