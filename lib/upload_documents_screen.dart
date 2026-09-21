import 'package:flutter/material.dart';

class UploadDocumentsScreen extends StatelessWidget {
  const UploadDocumentsScreen({super.key});

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
                  const Text(
                    'Step 4 of 4',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),

              const SizedBox(height: 35),

              const Text(
                'Upload Documents',
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.w700),
              ),

              const SizedBox(height: 10),

              const Text(
                'Upload clear images of the required documents to complete your verification.',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF777777),
                  height: 1.3,
                ),
              ),

              const SizedBox(height: 28),

              _documentCard(
                title: 'Aadhaar Card - Front',
                subtitle: 'Upload front side',
              ),

              const SizedBox(height: 14),

              _documentCard(
                title: 'Aadhaar Card - Back',
                subtitle: 'Upload back side',
              ),

              const SizedBox(height: 14),

              _documentCard(
                title: 'Driving Licence',
                subtitle: 'Upload driving licence',
              ),

              const SizedBox(height: 14),

              _documentCard(
                title: 'Profile Photo',
                subtitle: 'Upload a clear profile photo',
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF079C3B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Complete Registration',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _documentCard({required String title, required String subtitle}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFE7F7EA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.upload_file, color: Color(0xFF079C3B)),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF777777),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          const Icon(Icons.chevron_right, color: Color(0xFF777777)),
        ],
      ),
    );
  }
}
