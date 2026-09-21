import 'package:flutter/material.dart';

import 'state/registration_draft.dart';
import 'submitted_screen.dart';
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
      setState(
        () => error = 'Attach Aadhaar front, Aadhaar back and a profile photo.',
      );
      return;
    }
    Navigator.push(context, evuddyRoute(const SubmittedScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final d = registrationDraft;
    return AuthScreen(
      title: 'Documents',
      subtitle: 'Tap to mark attached. Files stay on this phone until upload is live.',
      step: 4,
      error: error,
      footer: EvuddyButton(
        label: 'Submit',
        onPressed: _complete,
      ),
      children: [
        DocTile(
          title: 'Aadhaar — front',
          subtitle: 'Required',
          icon: Icons.badge_outlined,
          selected: d.aadhaarFront,
          onTap: () => _toggle(() => d.aadhaarFront = !d.aadhaarFront),
        ),
        DocTile(
          title: 'Aadhaar — back',
          subtitle: 'Required',
          icon: Icons.badge_outlined,
          selected: d.aadhaarBack,
          onTap: () => _toggle(() => d.aadhaarBack = !d.aadhaarBack),
        ),
        DocTile(
          title: 'Licence — front',
          subtitle: 'Optional',
          icon: Icons.directions_car_outlined,
          selected: d.licenseFront,
          onTap: () => _toggle(() => d.licenseFront = !d.licenseFront),
        ),
        DocTile(
          title: 'Licence — back',
          subtitle: 'Optional',
          icon: Icons.directions_car_outlined,
          selected: d.licenseBack,
          onTap: () => _toggle(() => d.licenseBack = !d.licenseBack),
        ),
        DocTile(
          title: 'Profile photo',
          subtitle: 'Required',
          icon: Icons.person_outline_rounded,
          selected: d.profilePhoto,
          onTap: () => _toggle(() => d.profilePhoto = !d.profilePhoto),
        ),
      ],
    );
  }
}
