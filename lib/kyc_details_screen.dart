import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'state/registration_draft.dart';
import 'upload_documents_screen.dart';
import 'widgets/chrome.dart';
import 'widgets/voice_fill.dart';

class KycDetailsScreen extends StatefulWidget {
  const KycDetailsScreen({super.key});

  @override
  State<KycDetailsScreen> createState() => _KycDetailsScreenState();
}

class _KycDetailsScreenState extends State<KycDetailsScreen> {
  late final TextEditingController aadhaar;
  late final TextEditingController license;
  late final TextEditingController ig;
  late final TextEditingController fb;
  late final TextEditingController r1n;
  late final TextEditingController r1p;
  late final TextEditingController r2n;
  late final TextEditingController r2p;
  String? error;

  @override
  void initState() {
    super.initState();
    final d = registrationDraft;
    aadhaar = TextEditingController(text: d.aadhaar);
    license = TextEditingController(text: d.drivingLicense);
    ig = TextEditingController(text: d.instagramId);
    fb = TextEditingController(text: d.facebookId);
    r1n = TextEditingController(text: d.reference1Name);
    r1p = TextEditingController(text: d.reference1Phone);
    r2n = TextEditingController(text: d.reference2Name);
    r2p = TextEditingController(text: d.reference2Phone);
  }

  @override
  void dispose() {
    for (final c in [aadhaar, license, ig, fb, r1n, r1p, r2n, r2p]) {
      c.dispose();
    }
    super.dispose();
  }

  void _continue() {
    final a = aadhaar.text.replaceAll(RegExp(r'\D'), '');
    if (!RegExp(r'^\d{12}$').hasMatch(a)) {
      setState(() => error = 'Aadhaar number must be exactly 12 digits.');
      return;
    }
    final dl = license.text.toUpperCase().replaceAll(' ', '');
    if (dl.isNotEmpty && !RegExp(r'^[A-Z]{2}\d{13}$').hasMatch(dl)) {
      setState(() => error = 'Enter a valid Indian driving license number, or leave it blank.');
      return;
    }
    if (r1n.text.trim().isNotEmpty &&
        !RegExp(r"^[A-Za-z][A-Za-z\s'.-]{2,49}$").hasMatch(r1n.text.trim())) {
      setState(() => error = 'Enter a valid Reference Person 1 name.');
      return;
    }
    if (r1p.text.trim().isNotEmpty &&
        !RegExp(r'^[6-9]\d{9}$').hasMatch(r1p.text.replaceAll(RegExp(r'\D'), ''))) {
      setState(() => error = 'Enter a valid Reference Person 1 phone number.');
      return;
    }
    if (r2n.text.trim().isNotEmpty &&
        !RegExp(r"^[A-Za-z][A-Za-z\s'.-]{2,49}$").hasMatch(r2n.text.trim())) {
      setState(() => error = 'Enter a valid Reference Person 2 name.');
      return;
    }
    if (r2p.text.trim().isNotEmpty &&
        !RegExp(r'^[6-9]\d{9}$').hasMatch(r2p.text.replaceAll(RegExp(r'\D'), ''))) {
      setState(() => error = 'Enter a valid Reference Person 2 phone number.');
      return;
    }
    registrationDraft
      ..aadhaar = a
      ..drivingLicense = dl
      ..instagramId = ig.text.trim()
      ..facebookId = fb.text.trim()
      ..reference1Name = r1n.text.trim()
      ..reference1Phone = r1p.text.replaceAll(RegExp(r'\D'), '')
      ..reference2Name = r2n.text.trim()
      ..reference2Phone = r2p.text.replaceAll(RegExp(r'\D'), '');
    Navigator.push(context, evuddyRoute(const UploadDocumentsScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return AuthScreen(
      kicker: 'KYC  ·  Step 3 of 4',
      title: 'KYC details',
      subtitle:
          'Aadhaar is required. Licence and references are optional. Tap the mic to speak numbers.',
      step: 3,
      error: error,
      footer: EvuddyButton(label: 'Continue', onPressed: _continue),
      children: [
        EvuddyField(
          label: 'AADHAAR NUMBER *',
          hint: '12 digits',
          controller: aadhaar,
          keyboardType: TextInputType.number,
          maxLength: 12,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          voiceKind: VoiceKind.aadhaar,
        ),
        const SizedBox(height: 16),
        EvuddyField(
          label: 'DRIVING LICENCE',
          hint: 'Optional · UP1420110012345',
          controller: license,
          textCapitalization: TextCapitalization.characters,
          voiceKind: VoiceKind.license,
        ),
        const SizedBox(height: 16),
        EvuddyField(label: 'INSTAGRAM', hint: 'Optional', controller: ig),
        const SizedBox(height: 16),
        EvuddyField(label: 'FACEBOOK', hint: 'Optional', controller: fb),
        const SizedBox(height: 24),
        const WelcomeRule(caption: 'References'),
        const SizedBox(height: 16),
        EvuddyField(label: 'REFERENCE 1 NAME', hint: 'Optional', controller: r1n, voiceKind: VoiceKind.name),
        const SizedBox(height: 16),
        EvuddyField(
          label: 'REFERENCE 1 MOBILE',
          hint: 'Optional',
          controller: r1p,
          keyboardType: TextInputType.phone,
          maxLength: 10,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          prefix: const PhonePrefix(),
          voiceKind: VoiceKind.phone,
        ),
        const SizedBox(height: 16),
        EvuddyField(label: 'REFERENCE 2 NAME', hint: 'Optional', controller: r2n, voiceKind: VoiceKind.name),
        const SizedBox(height: 16),
        EvuddyField(
          label: 'REFERENCE 2 MOBILE',
          hint: 'Optional',
          controller: r2p,
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
