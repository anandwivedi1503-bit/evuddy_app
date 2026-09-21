import 'package:flutter/material.dart';

import 'upload_documents_screen.dart';

class KycDetailsScreen extends StatelessWidget {
  const KycDetailsScreen({super.key});

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
                  _backButton(context),
                  const Spacer(),
                  const Text(
                    'Step 3 of 4',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),

              const SizedBox(height: 35),

              const Text(
                'KYC Details',
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.w700),
              ),

              const SizedBox(height: 10),

              const Text(
                'Enter your details exactly as they appear on your identity documents.',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF777777),
                  height: 1.3,
                ),
              ),

              const SizedBox(height: 28),

              _field('AADHAAR NUMBER', 'Enter Aadhaar number'),
              const SizedBox(height: 18),
              _field('PAN NUMBER', 'Enter PAN number'),
              const SizedBox(height: 18),
              _field('ADDRESS', 'Enter your address'),
              const SizedBox(height: 18),
              _field('PIN CODE', 'Enter PIN code'),

              const SizedBox(height: 30),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lock_outline, color: Color(0xFF079C3B)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Your KYC information is securely protected.',
                        style: TextStyle(color: Color(0xFF666666)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const UploadDocumentsScreen(),
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

  Widget _backButton(BuildContext context) {
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

  Widget _field(String label, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 9),
        Container(
          height: 55,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(11),
          ),
          child: TextField(
            decoration: InputDecoration(
              hintText: hint,
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
