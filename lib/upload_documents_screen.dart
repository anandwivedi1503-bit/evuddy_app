import 'package:flutter/material.dart';

import 'state/registration_draft.dart';
import 'submitted_screen.dart';
import 'theme/evuddy.dart';
import 'widgets/chrome.dart';

class UploadDocumentsScreen extends StatefulWidget {
  const UploadDocumentsScreen({super.key});

  @override
  State<UploadDocumentsScreen> createState() => _UploadDocumentsScreenState();
}

class _UploadDocumentsScreenState extends State<UploadDocumentsScreen> {
  String? error;

  void _toggle(void Function() fn) {
    setState(fn);
  }

  void _complete() {
    final d = registrationDraft;
    if (!d.aadhaarFront || !d.aadhaarBack || !d.profilePhoto) {
      setState(() => error = 'Website requires Aadhaar front, Aadhaar back and a profile photo.');
      return;
    }
    Navigator.push(context, evuddyRoute(const SubmittedScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final d = registrationDraft;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const EvuddyHeader(trailing: StepChip(step: 4, of: 4)),
              const SizedBox(height: 24),
              const WelcomeRule(caption: 'DOCUMENTS'),
              const SizedBox(height: 24),
              Text('Upload documents', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              const Text(
                'Figma showed one licence card. The website needs Aadhaar front & back, profile photo, and optional licence front & back. Tap to mark attached — files are not sent to the server yet.',
              ),
              const SizedBox(height: 22),
              _DocTile(
                title: 'Aadhaar card — front',
                subtitle: 'Required',
                selected: d.aadhaarFront,
                onTap: () => _toggle(() => d.aadhaarFront = !d.aadhaarFront),
              ),
              _DocTile(
                title: 'Aadhaar card — back',
                subtitle: 'Required',
                selected: d.aadhaarBack,
                onTap: () => _toggle(() => d.aadhaarBack = !d.aadhaarBack),
              ),
              _DocTile(
                title: 'Driving licence — front',
                subtitle: 'Optional on website',
                selected: d.licenseFront,
                onTap: () => _toggle(() => d.licenseFront = !d.licenseFront),
              ),
              _DocTile(
                title: 'Driving licence — back',
                subtitle: 'Optional on website',
                selected: d.licenseBack,
                onTap: () => _toggle(() => d.licenseBack = !d.licenseBack),
              ),
              _DocTile(
                title: 'Profile photo',
                subtitle: 'Required',
                selected: d.profilePhoto,
                onTap: () => _toggle(() => d.profilePhoto = !d.profilePhoto),
              ),
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(error!, style: const TextStyle(color: Color(0xFFB42318), fontSize: 13)),
              ],
              const SizedBox(height: 20),
              EvuddyButton(label: 'Complete registration', onPressed: _complete),
            ],
          ),
        ),
      ),
    );
  }
}

class _DocTile extends StatelessWidget {
  const _DocTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Evuddy.paper,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: selected ? Evuddy.green : Evuddy.line),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Evuddy.greenSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    selected ? Icons.check_rounded : Icons.upload_file_outlined,
                    color: Evuddy.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                      const SizedBox(height: 2),
                      Text(
                        selected ? 'Attached on this device' : subtitle,
                        style: const TextStyle(color: Evuddy.muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: selected ? Evuddy.green : Evuddy.muted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
