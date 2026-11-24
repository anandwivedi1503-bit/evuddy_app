import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'api/evuddy_api.dart';
import 'state/registration_draft.dart';
import 'upload_documents_screen.dart';
import 'widgets/booking_ui.dart';
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
  String pickupCityAck = registrationDraft.pickupCityAck;
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

  Future<void> _continue() async {
    if (pickupCityAck != 'LUCKNOW') {
      setState(() {
        error = pickupCityAck == 'OTHER'
            ? 'EVUDDY currently accepts new rider registrations for Lucknow pickups only. Select Lucknow only if you plan to collect from a Lucknow hub. Your current location and Aadhaar address may be elsewhere.'
            : 'Select Lucknow as your intended pickup city to register. Your current location and Aadhaar address may be elsewhere.';
      });
      return;
    }
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
        !RtoAgreement.namePattern.hasMatch(r1n.text.trim())) {
      setState(() => error = 'Enter a valid Reference Person 1 name.');
      return;
    }
    if (r1p.text.trim().isNotEmpty &&
        !RegExp(r'^[6-9]\d{9}$').hasMatch(r1p.text.replaceAll(RegExp(r'\D'), ''))) {
      setState(() => error = 'Enter a valid Reference Person 1 phone number.');
      return;
    }
    if (r2n.text.trim().isNotEmpty &&
        !RtoAgreement.namePattern.hasMatch(r2n.text.trim())) {
      setState(() => error = 'Enter a valid Reference Person 2 name.');
      return;
    }
    if (r2p.text.trim().isNotEmpty &&
        !RegExp(r'^[6-9]\d{9}$').hasMatch(r2p.text.replaceAll(RegExp(r'\D'), ''))) {
      setState(() => error = 'Enter a valid Reference Person 2 phone number.');
      return;
    }
    registrationDraft
      ..pickupCityAck = pickupCityAck
      ..aadhaar = a
      ..drivingLicense = dl
      ..instagramId = ig.text.trim()
      ..facebookId = fb.text.trim()
      ..reference1Name = r1n.text.trim()
      ..reference1Phone = r1p.text.replaceAll(RegExp(r'\D'), '')
      ..reference2Name = r2n.text.trim()
      ..reference2Phone = r2p.text.replaceAll(RegExp(r'\D'), '');
    await registrationDraft.persist();
    if (!mounted) return;
    Navigator.push(context, evuddyRoute(const UploadDocumentsScreen()));
  }

  Widget _serviceCityOption({
    required String value,
    required String title,
    String? subtitle,
  }) {
    final selected = pickupCityAck == value;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => setState(() {
        pickupCityAck = value;
        error = null;
      }),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: selected ? const Color(0xFF18B368) : const Color(0xFFE5E7EB),
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected
                  ? const Color(0xFF18B368)
                  : const Color(0xFF737373),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(subtitle, style: const TextStyle(height: 1.35)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BookStage(
      kicker: 'KYC',
      title: 'Verify who you are',
      subtitle:
          'Aadhaar is required so ops can approve you. Licence and references help the yard — optional.',
      step: 3,
      error: error,
      footer: EvuddyButton(sun: true, label: 'Continue', onPressed: _continue),
      children: [
        FormDeck(
          eyebrow: 'Service area',
          title: 'Where will you pick up?',
          icon: Icons.location_on_rounded,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                'New rider registration is currently for Lucknow pickups. You can register while elsewhere if you plan to collect from a Lucknow hub. Your Aadhaar address does not need to be in Lucknow.',
                style: TextStyle(height: 1.45),
              ),
            ),
            _serviceCityOption(
              value: 'LUCKNOW',
              title: 'I plan to pick up from a Lucknow, Uttar Pradesh hub',
            ),
            _serviceCityOption(
              value: 'OTHER',
              title: 'I plan to pick up in another city',
              subtitle: 'New rider registration is not open there yet.',
            ),
          ],
        ),
        const SizedBox(height: 16),
        FormDeck(
          eyebrow: 'Identity',
          title: 'Government IDs',
          icon: Icons.badge_rounded,
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
          ],
        ),
        const SizedBox(height: 16),
        FormDeck(
          eyebrow: 'Yard contacts',
          title: 'References',
          icon: Icons.groups_rounded,
          children: [
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
        ),
      ],
    );
  }
}
