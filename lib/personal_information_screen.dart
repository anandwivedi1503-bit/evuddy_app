import 'package:flutter/material.dart';

import 'registration_otp_screen.dart';

class PersonalInformationScreen extends StatelessWidget {
  const PersonalInformationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FBEF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _topBar(context),

              const SizedBox(height: 36),

              const Text(
                'Start Your Journey With EVUDDY',
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.w700),
              ),

              const SizedBox(height: 10),

              const Text(
                'Tell us a little about yourself to create your EVUDDY rider account.',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF777777),
                  height: 1.3,
                ),
              ),

              const SizedBox(height: 30),

              _field('FULL NAME', 'Enter your full name'),
              const SizedBox(height: 18),
              _field('EMAIL ADDRESS', 'Enter your email address'),
              const SizedBox(height: 18),
              _field('DATE OF BIRTH', 'DD / MM / YYYY'),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RegistrationOtpScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF079C3B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Continue',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 10),
                      Icon(Icons.arrow_forward),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
          child: IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        const Spacer(),
        Image.asset('assets/images/evuddy_logo.png', width: 165, height: 55),
        const Spacer(),
        const SizedBox(width: 48),
      ],
    );
  }

  Widget _field(String label, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        Container(
          height: 56,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(11),
          ),
          child: TextField(
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFF999999)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 17,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
