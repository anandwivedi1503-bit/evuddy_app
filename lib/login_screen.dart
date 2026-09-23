import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'api/evuddy_api.dart';
import 'state/registration_draft.dart';
import 'theme/evuddy.dart';
import 'verify_mobile_otp_screen.dart';
import 'widgets/chrome.dart';
import 'widgets/voice_fill.dart';

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
          'Same fields as evuddy.com/register. Tap the mic to speak the form. We’ll text a Firebase OTP.',
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
          hint: 'As on Aadhaar · or tap the mic',
          controller: name,
          textCapitalization: TextCapitalization.words,
          voiceKind: VoiceKind.name,
        ),
        const SizedBox(height: 16),
        EvuddyField(
          label: 'MOBILE NUMBER *',
          hint: '10-digit mobile · or speak it',
          controller: phone,
          keyboardType: TextInputType.phone,
          maxLength: 10,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          prefix: const PhonePrefix(),
          voiceKind: VoiceKind.phone,
        ),
        const SizedBox(height: 16),
        EvuddyField(
          label: 'EMAIL *',
          hint: 'name@email.com · say “at” and “dot”',
          controller: email,
          keyboardType: TextInputType.emailAddress,
          voiceKind: VoiceKind.email,
        ),
        const SizedBox(height: 12),
        Material(
          color: Evuddy.greenSoft,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                VoiceMicButton(
                  kind: VoiceKind.free,
                  tooltip: 'Speak name, mobile and email together',
                  onResult: (spoken) {
                    final parsed = VoiceFill.parseRegister(spoken);
                    if (parsed['name'] != null) name.text = parsed['name']!;
                    if (parsed['phone'] != null) phone.text = parsed['phone']!;
                    if (parsed['email'] != null) email.text = parsed['email']!;
                    setState(() {});
                  },
                ),
                const Expanded(
                  child: Text('Speak name, mobile and email in one go'),
                ),
              ],
            ),
          ),
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
