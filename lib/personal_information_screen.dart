import 'package:flutter/material.dart';

import 'registration_otp_screen.dart';
import 'state/registration_draft.dart';
import 'theme/evuddy.dart';
import 'widgets/chrome.dart';

const comingThroughOptions = [
  'Direct / EVUDDY',
  'EVUDDY Dealer',
  'EVUDDY Distributor',
  'Fleet Partner',
  'Flipkart Minutes Partner',
  'Zomato Partner',
];

class PersonalInformationScreen extends StatefulWidget {
  const PersonalInformationScreen({super.key});

  @override
  State<PersonalInformationScreen> createState() =>
      _PersonalInformationScreenState();
}

class _PersonalInformationScreenState extends State<PersonalInformationScreen> {
  late final TextEditingController name;
  late final TextEditingController email;
  late final TextEditingController dob;
  String comingThrough = registrationDraft.comingThrough;
  String? error;

  @override
  void initState() {
    super.initState();
    name = TextEditingController(text: registrationDraft.fullName);
    email = TextEditingController(text: registrationDraft.email);
    dob = TextEditingController(text: registrationDraft.dateOfBirth);
  }

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    dob.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 24, 1, 1),
      firstDate: DateTime(1950),
      lastDate: DateTime(now.year - 16, now.month, now.day),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Evuddy.green,
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked == null) return;
    final dd = picked.day.toString().padLeft(2, '0');
    final mm = picked.month.toString().padLeft(2, '0');
    dob.text = '$dd / $mm / ${picked.year}';
    setState(() {});
  }

  void _continue() {
    final n = name.text.trim();
    final e = email.text.trim().toLowerCase();
    if (!RegExp(r"^[A-Za-z][A-Za-z\s'.-]{2,79}$").hasMatch(n)) {
      setState(() => error = 'Enter your full name as on Aadhaar.');
      return;
    }
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$').hasMatch(e)) {
      setState(() => error = 'Enter a valid email address.');
      return;
    }
    registrationDraft
      ..fullName = n
      ..email = e
      ..dateOfBirth = dob.text.trim()
      ..comingThrough = comingThrough;
    Navigator.push(context, evuddyRoute(const RegistrationOtpScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return AuthScreen(
      title: 'Your details',
      subtitle: 'Use the name on your Aadhaar.',
      step: 2,
      error: error,
      footer: EvuddyButton(label: 'Continue', onPressed: _continue),
      children: [
        EvuddyField(
          label: 'Full name',
          hint: 'As printed on Aadhaar',
          controller: name,
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 16),
        EvuddyField(
          label: 'Email',
          hint: 'name@email.com',
          controller: email,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        EvuddyField(
          label: 'Date of birth',
          hint: 'DD / MM / YYYY',
          controller: dob,
          readOnly: true,
          onTap: _pickDob,
          suffix: const Padding(
            padding: EdgeInsets.only(right: 14),
            child: Icon(Icons.calendar_today_outlined, size: 18, color: Evuddy.muted),
          ),
        ),
        const SizedBox(height: 22),
        Text('Coming through', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        SelectList(
          options: comingThroughOptions,
          value: comingThrough,
          onChanged: (v) => setState(() => comingThrough = v),
        ),
      ],
    );
  }
}
