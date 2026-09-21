import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'api/evuddy_api.dart';
import 'state/registration_draft.dart';
import 'verify_mobile_otp_screen.dart';
import 'widgets/chrome.dart';

const comingThroughOptions = [
  'Direct / EVUDDY',
  'Flipkart Minutes',
  'Zomato',
  'Swiggy',
  'Instamart',
  'Blinkit',
  'Zepto',
  'Other',
];

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final TextEditingController name;
  late final TextEditingController phone;
  late final TextEditingController email;
  String comingThrough = registrationDraft.comingThrough;
  String? error;
  bool busy = false;

  @override
  void initState() {
    super.initState();
    name = TextEditingController(text: registrationDraft.fullName);
    phone = TextEditingController(text: registrationDraft.phone);
    email = TextEditingController(text: registrationDraft.email);
    EvuddyApi.health().then((ok) {
      if (!mounted) return;
      setState(() => registrationDraft.apiOnline = ok);
    });
  }

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    email.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    FocusScope.of(context).unfocus();
    final n = name.text.trim().replaceAll(RegExp(r'\s+'), ' ');
    final p = phone.text.replaceAll(RegExp(r'\D'), '');
    final e = email.text.trim().toLowerCase();
    if (!RegExp(r"^[A-Za-z][A-Za-z\s'.-]{2,49}$").hasMatch(n)) {
      setState(() => error = 'Enter a valid full name using letters only.');
      return;
    }
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(p)) {
      setState(() => error = 'Enter a valid 10 digit Indian mobile number.');
      return;
    }
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$').hasMatch(e)) {
      setState(() => error = 'Enter a valid email address.');
      return;
    }
    registrationDraft
      ..fullName = n
      ..phone = p
      ..email = e
      ..comingThrough = comingThrough
      ..phoneVerified = false
      ..otpGate = 'register';
    setState(() {
      error = null;
      busy = true;
    });
    if (mounted) {
      setState(() => busy = false);
      Navigator.push(context, evuddyRoute(const VerifyMobileOtpScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScreen(
      showBack: false,
      kicker: 'Personal  ·  Step 1 of 4',
      title: 'Personal Information',
      subtitle:
          'Same fields as evuddy.com/register. We’ll text a Firebase OTP to this number.',
      step: 1,
      error: error,
      footer: EvuddyButton(
        label: 'Send OTP',
        busy: busy,
        onPressed: busy ? null : _continue,
      ),
      children: [
        if (registrationDraft.apiOnline)
          const Padding(
            padding: EdgeInsets.only(bottom: 18),
            child: InfoNote(text: 'Connected to evuddy.com — rider records use the live API.'),
          ),
        EvuddyField(
          label: 'FULL NAME *',
          hint: 'As on Aadhaar',
          controller: name,
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 16),
        EvuddyField(
          label: 'MOBILE NUMBER *',
          hint: '10-digit mobile',
          controller: phone,
          keyboardType: TextInputType.phone,
          maxLength: 10,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          prefix: const PhonePrefix(),
        ),
        const SizedBox(height: 16),
        EvuddyField(
          label: 'EMAIL *',
          hint: 'name@email.com',
          controller: email,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 20),
        Text('COMING THROUGH', style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 10),
        ChoicePills(
          options: comingThroughOptions,
          value: comingThrough,
          onChanged: (v) => setState(() => comingThrough = v),
        ),
      ],
    );
  }
}
