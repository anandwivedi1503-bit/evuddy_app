import 'package:flutter/material.dart';

import 'kyc_details_screen.dart';

class RegistrationOtpScreen extends StatefulWidget {
  const RegistrationOtpScreen({super.key});

  @override
  State<RegistrationOtpScreen> createState() => _RegistrationOtpScreenState();
}

class _RegistrationOtpScreenState extends State<RegistrationOtpScreen> {
  final TextEditingController otpController = TextEditingController();

  @override
  void dispose() {
    otpController.dispose();
    super.dispose();
  }

  void _continue() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const KycDetailsScreen()),
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
                  const Text(
                    'Step 2 of 4',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),

              const SizedBox(height: 35),

              const Text(
                'OTP Verification',
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.w700),
              ),

              const SizedBox(height: 10),

              const Text(
                'Verify your phone number to continue your EVUDDY registration.',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF777777),
                  height: 1.3,
                ),
              ),

              const SizedBox(height: 30),

              const Text(
                'ENTER OTP',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),

              const SizedBox(height: 10),

              TextField(
                controller: otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  counterText: '',
                  hintText: 'Enter 6-digit OTP',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(11),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 15),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE7F7EA),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Text(
                  'Phone Number Verified',
                  style: TextStyle(
                    color: Color(0xFF078B36),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Your information is securely protected and will only be used for account verification.',
                  style: TextStyle(color: Color(0xFF666666), height: 1.35),
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _continue,
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
                        'Continue to KYC',
                        style: TextStyle(fontWeight: FontWeight.w600),
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
        onPressed: () => Navigator.pop(context),
      ),
    );
  }
}
