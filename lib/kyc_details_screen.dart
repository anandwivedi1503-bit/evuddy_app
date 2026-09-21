import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'state/registration_draft.dart';
import 'upload_documents_screen.dart';
import 'widgets/chrome.dart';

class KycDetailsScreen extends StatefulWidget {
  const KycDetailsScreen({super.key});

  @override
  State<KycDetailsScreen> createState() => _KycDetailsScreenState();
}

class _KycDetailsScreenState extends State<KycDetailsScreen> {
  late final TextEditingController aadhaar;
  late final TextEditingController pan;
  late final TextEditingController license;
  late final TextEditingController address;
  late final TextEditingController pin;
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
    pan = TextEditingController(text: d.pan);
    license = TextEditingController(text: d.drivingLicense);
    address = TextEditingController(text: d.address);
    pin = TextEditingController(text: d.pinCode);
    r1n = TextEditingController(text: d.reference1Name);
    r1p = TextEditingController(text: d.reference1Phone);
    r2n = TextEditingController(text: d.reference2Name);
    r2p = TextEditingController(text: d.reference2Phone);
  }

  @override
  void dispose() {
    for (final c in [aadhaar, pan, license, address, pin, r1n, r1p, r2n, r2p]) {
      c.dispose();
    }
    super.dispose();
  }

  void _continue() {
    final a = aadhaar.text.replaceAll(RegExp(r'\D'), '');
    if (!RegExp(r'^\d{12}$').hasMatch(a)) {
      setState(() => error = 'Aadhaar must be exactly 12 digits.');
      return;
    }
    final dl = license.text.toUpperCase().replaceAll(' ', '');
    if (dl.isNotEmpty && !RegExp(r'^[A-Z]{2}\d{13}$').hasMatch(dl)) {
      setState(() => error = 'Licence should look like UP1420110012345, or leave it blank.');
      return;
    }
    if (r1n.text.trim().isEmpty ||
        !RegExp(r'^[6-9]\d{9}$').hasMatch(r1p.text.replaceAll(RegExp(r'\D'), ''))) {
      setState(() => error = 'Reference 1 needs a name and a valid mobile.');
      return;
    }
    if (r2n.text.trim().isEmpty ||
        !RegExp(r'^[6-9]\d{9}$').hasMatch(r2p.text.replaceAll(RegExp(r'\D'), ''))) {
      setState(() => error = 'Reference 2 needs a name and a valid mobile.');
      return;
    }
    registrationDraft
      ..aadhaar = a
      ..pan = pan.text.trim().toUpperCase()
      ..drivingLicense = dl
      ..address = address.text.trim()
      ..pinCode = pin.text.trim()
      ..reference1Name = r1n.text.trim()
      ..reference1Phone = r1p.text.replaceAll(RegExp(r'\D'), '')
      ..reference2Name = r2n.text.trim()
      ..reference2Phone = r2p.text.replaceAll(RegExp(r'\D'), '');
    Navigator.push(context, evuddyRoute(const UploadDocumentsScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return AuthScreen(
      kicker: 'Identity  ·  KYC',
      title: 'KYC details',
      subtitle:
          'Enter details as on your documents. Licence is optional. Two references are required.',
      step: 3,
      error: error,
      footer: EvuddyButton(label: 'Continue', onPressed: _continue),
      children: [
        EvuddyField(
          label: 'AADHAAR NUMBER',
          hint: '12 digits',
          controller: aadhaar,
          keyboardType: TextInputType.number,
          maxLength: 12,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: 14),
        EvuddyField(
          label: 'PAN NUMBER',
          hint: 'Optional',
          controller: pan,
          textCapitalization: TextCapitalization.characters,
          maxLength: 10,
        ),
        const SizedBox(height: 14),
        EvuddyField(
          label: 'DRIVING LICENCE',
          hint: 'Optional · e.g. UP1420110012345',
          controller: license,
          textCapitalization: TextCapitalization.characters,
        ),
        const SizedBox(height: 14),
        EvuddyField(
          label: 'ADDRESS',
          hint: 'Residence address',
          controller: address,
          textCapitalization: TextCapitalization.sentences,
        ),
        const SizedBox(height: 14),
        EvuddyField(
          label: 'PIN CODE',
          hint: '6 digits',
          controller: pin,
          keyboardType: TextInputType.number,
          maxLength: 6,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: 24),
        const WelcomeRule(caption: 'References'),
        const SizedBox(height: 16),
        EvuddyField(label: 'REFERENCE 1 NAME', hint: 'Full name', controller: r1n),
        const SizedBox(height: 14),
        EvuddyField(
          label: 'REFERENCE 1 MOBILE',
          hint: '10 digits',
          controller: r1p,
          keyboardType: TextInputType.phone,
          maxLength: 10,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          prefix: const PhonePrefix(),
        ),
        const SizedBox(height: 14),
        EvuddyField(label: 'REFERENCE 2 NAME', hint: 'Full name', controller: r2n),
        const SizedBox(height: 14),
        EvuddyField(
          label: 'REFERENCE 2 MOBILE',
          hint: '10 digits',
          controller: r2p,
          keyboardType: TextInputType.phone,
          maxLength: 10,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          prefix: const PhonePrefix(),
        ),
        const SizedBox(height: 16),
        const InfoNote(
          text:
              'Ops reviews KYC before Book EV opens — the same rule as the website.',
        ),
      ],
    );
  }
}
