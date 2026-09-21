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
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const EvuddyHeader(trailing: StepChip(step: 2, of: 4)),
              const SizedBox(height: 24),
              const WelcomeRule(caption: 'CREATE YOUR RIDER ACCOUNT'),
              const SizedBox(height: 24),
              Text(
                'Start your journey\nwith EVUDDY',
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 10),
              const Text(
                'The website asks for name, email and how you came in. Date of birth is extra on this Figma flow and is stored only in the app for now.',
              ),
              const SizedBox(height: 26),
              EvuddyField(
                label: 'FULL NAME',
                hint: 'As printed on Aadhaar',
                controller: name,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              EvuddyField(
                label: 'EMAIL ADDRESS',
                hint: 'name@email.com',
                controller: email,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              EvuddyField(
                label: 'DATE OF BIRTH',
                hint: 'DD / MM / YYYY',
                controller: dob,
                keyboardType: TextInputType.datetime,
              ),
              const SizedBox(height: 16),
              Text('COMING THROUGH', style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Evuddy.wash,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: comingThrough,
                    items: comingThroughOptions
                        .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                        .toList(),
                    onChanged: (v) => setState(() => comingThrough = v!),
                  ),
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: 12),
                Text(error!, style: const TextStyle(color: Color(0xFFB42318), fontSize: 13)),
              ],
              const SizedBox(height: 28),
              EvuddyButton(label: 'Continue', onPressed: _continue),
            ],
          ),
        ),
      ),
    );
  }
}
