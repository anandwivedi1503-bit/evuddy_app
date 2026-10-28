import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'api/evuddy_api.dart';
import 'api/firebase_phone.dart';
import 'services/user_facing_error.dart';
import 'state/registration_draft.dart';
import 'theme/evuddy.dart';
import 'widgets/chrome.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  late final TextEditingController name;
  late final TextEditingController email;
  bool saving = false;
  String? error;
  String? ok;

  @override
  void initState() {
    super.initState();
    final d = registrationDraft;
    name = TextEditingController(text: d.fullName);
    email = TextEditingController(text: d.email);
  }

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final riderId = registrationDraft.riderId;
    if (riderId == null || riderId.isEmpty) {
      setState(() => error = 'Complete registration before editing profile.');
      return;
    }
    final fullName = name.text.trim();
    final mail = email.text.trim();
    if (fullName.length < 2) {
      setState(() => error = 'Enter your full name.');
      return;
    }
    if (!mail.contains('@')) {
      setState(() => error = 'Enter a valid email for receipts and alerts.');
      return;
    }
    setState(() {
      saving = true;
      error = null;
      ok = null;
    });
    try {
      final token = await registrationDraft.freshToken(force: true);
      if (token == null || EvuddyFirebase.jwtExpired(token)) {
        setState(() {
          saving = false;
          error = 'Session expired. Log in with OTP again.';
        });
        return;
      }
      await EvuddyApi.updateRiderProfile(
        idToken: token,
        riderId: riderId,
        fullName: fullName,
        email: mail,
      );
      registrationDraft
        ..fullName = fullName
        ..email = mail;
      await registrationDraft.persist();
      if (!mounted) return;
      setState(() {
        saving = false;
        ok = 'Profile saved on evuddy.com. Receipts and SMS use this email and registered mobile.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        saving = false;
        error = userFacingError(e, fallback: 'Could not save profile. Try again.');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScreen(
      kicker: 'Your details',
      title: 'Update profile',
      subtitle:
          'Name and email sync with evuddy.com CRM. Mobile number stays verified by OTP — change it only via helpdesk.',
      error: error,
      footer: EvuddyButton(
        label: saving ? 'Saving…' : 'Save profile',
        busy: saving,
        onPressed: saving ? null : _save,
      ),
      children: [
        if (ok != null) ...[
          InfoNote(text: ok!),
          const SizedBox(height: 14),
        ],
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('REGISTERED MOBILE', style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: 6),
              Text(
                registrationDraft.phoneDisplay,
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 17),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: name,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Full name'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: email,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          decoration: const InputDecoration(labelText: 'Email for receipts'),
        ),
      ],
    );
  }
}
