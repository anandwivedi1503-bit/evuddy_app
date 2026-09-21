import 'package:flutter/material.dart';

import 'personal_information_screen.dart';

class VerifyMobileOtpScreen extends StatefulWidget {
  const VerifyMobileOtpScreen({super.key});

  @override
  State<VerifyMobileOtpScreen> createState() => _VerifyMobileOtpScreenState();
}

class _VerifyMobileOtpScreenState extends State<VerifyMobileOtpScreen> {
  final List<TextEditingController> controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );

  int seconds = 42;

  @override
  void dispose() {
    for (final controller in controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _verify() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PersonalInformationScreen(),
      ),
    );
  }

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
              Row(
                children: [
                  _backButton(),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Step 2 of 3',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Help',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),

              const SizedBox(height: 35),

              const Text(
                'Confirm your mobile number',
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.w700),
              ),

              const SizedBox(height: 10),

              const Text(
                'Enter the 6-digit OTP sent to your mobile number.',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF777777),
                  height: 1.3,
                ),
              ),

              const SizedBox(height: 28),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  children: [
                    Text('🇮🇳', style: TextStyle(fontSize: 24)),
                    SizedBox(width: 10),
                    Text(
                      '+91',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text('88818 70016', style: TextStyle(fontSize: 16)),
                    Spacer(),
                    Text(
                      'Change',
                      style: TextStyle(
                        color: Color(0xFF079C3B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ENTER 6-DIGIT OTP',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Auto-read SMS',
                    style: TextStyle(color: Color(0xFF079C3B)),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              Row(
                children: List.generate(6, (index) {
                  return Expanded(
                    child: Container(
                      margin: EdgeInsets.only(right: index == 5 ? 0 : 7),
                      height: 54,
                      child: TextField(
                        controller: controllers[index],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        decoration: InputDecoration(
                          counterText: '',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 18),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: const Color(0xFFE7F7EA),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'OTP sent successfully to +918881870016',
                  style: TextStyle(
                    color: Color(0xFF078B36),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Center(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      color: Color(0xFF777777),
                      fontSize: 15,
                    ),
                    children: [
                      const TextSpan(text: "Didn't receive code? "),
                      TextSpan(
                        text: '00:$seconds',
                        style: const TextStyle(
                          color: Color(0xFF079C3B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 25),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: const Text('Resend'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _verify,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF079C3B),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: const Text('Verify OTP'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              const Center(
                child: Text(
                  'New rider? Complete registration',
                  style: TextStyle(
                    color: Color(0xFF079C3B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _backButton() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: IconButton(
        icon: const Icon(Icons.chevron_left),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
    );
  }
}
