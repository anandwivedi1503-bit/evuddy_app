import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'api/evuddy_api.dart';
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
  String? progress;
  bool busy = false;
  final _picker = ImagePicker();

  Future<void> _pick(void Function(String path) assign) async {
    final shot = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
    );
    if (shot == null) return;
    setState(() {
      assign(shot.path);
      error = null;
    });
  }

  Future<String> _up(String? path, String label) async {
    if (path == null) return '';
    setState(() => progress = 'Uploading $label…');
    final token = await _token();
    return EvuddyApi.uploadFile(file: File(path), idToken: token);
  }

  Future<String> _token() async {
    final user = FirebaseAuth.instance.currentUser;
    final fresh = await user?.getIdToken(true);
    if (fresh == null || fresh.isEmpty) {
      throw ApiException('Phone OTP expired. Go back and verify again.');
    }
    registrationDraft.firebaseIdToken = fresh;
    return fresh;
  }

  Future<void> _complete() async {
    final d = registrationDraft;
    if (d.aadhaarFrontPath == null || d.aadhaarBackPath == null || d.profilePhotoPath == null) {
      setState(() => error = 'Aadhaar front, Aadhaar back and a profile photo are required.');
      return;
    }
    if (d.aadhaarFrontPath == d.aadhaarBackPath) {
      setState(() => error = 'Aadhaar front and back cannot be the same file.');
      return;
    }
    setState(() {
      busy = true;
      error = null;
      progress = 'Preparing your registration…';
    });
    try {
      final front = await _up(d.aadhaarFrontPath, 'Aadhaar front');
      final back = await _up(d.aadhaarBackPath, 'Aadhaar back');
      final lf = await _up(d.licenseFrontPath, 'licence front');
      final lb = await _up(d.licenseBackPath, 'licence back');
      final photo = await _up(d.profilePhotoPath, 'profile photo');
      setState(() => progress = 'Creating your rider account…');
      final token = await _token();
      final result = await EvuddyApi.createRider({
        'fullName': d.fullName,
        'phone': d.phone,
        'email': d.email,
        'phoneVerified': d.phoneVerified,
        'firebaseUid': d.firebaseUid,
        'firebaseIdToken': token,
        'aadhaarNumber': d.aadhaar,
        'drivingLicense': d.drivingLicense,
        'aadhaarFrontUrl': front,
        'aadhaarBackUrl': back,
        'licenseFrontUrl': lf,
        'licenseBackUrl': lb,
        'profilePhotoUrl': photo,
        'instagramId': d.instagramId,
        'facebookId': d.facebookId,
        'comingThrough': d.comingThrough,
        'reference1Name': d.reference1Name,
        'reference1Phone': d.reference1Phone,
        'reference2Name': d.reference2Name,
        'reference2Phone': d.reference2Phone,
      });
      if (!mounted) return;
      if (result.riderExists && result.riderStatus == 'Rejected') {
        setState(() {
          busy = false;
          progress = null;
          error = result.message ?? 'This registration was rejected.';
        });
        return;
      }
      if (!result.ok && !result.riderExists) {
        setState(() {
          busy = false;
          progress = null;
          error = result.message ?? 'Could not create the rider.';
        });
        return;
      }
      d
        ..riderId = result.riderId
        ..approvalStatus = result.riderStatus ??
            (result.ok ? 'Under Review' : d.approvalStatus);
      Navigator.pushReplacement(context, evuddyRoute(const SubmittedScreen()));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        busy = false;
        progress = null;
        error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = registrationDraft;
    return AuthScreen(
      kicker: 'Documents  ·  Step 4 of 4',
      title: 'Upload documents',
      subtitle:
          'JPEG, PNG or WebP. Files go to the same /api/upload the website uses, then POST /api/riders.',
      step: 4,
      error: error,
      footer: EvuddyButton(
        label: busy ? (progress ?? 'Working…') : 'Complete registration',
        busy: busy,
        onPressed: busy ? null : _complete,
      ),
      children: [
        if (progress != null && busy) InfoNote(text: progress!),
        if (progress != null && busy) const SizedBox(height: 12),
        DocTile(
          title: 'Aadhaar card — front',
          subtitle: 'Required',
          icon: Icons.badge_outlined,
          selected: d.aadhaarFront,
          onTap: () => _pick((p) => d.aadhaarFrontPath = p),
        ),
        DocTile(
          title: 'Aadhaar card — back',
          subtitle: 'Required',
          icon: Icons.badge_outlined,
          selected: d.aadhaarBack,
          onTap: () => _pick((p) => d.aadhaarBackPath = p),
        ),
        DocTile(
          title: 'Driving licence — front',
          subtitle: 'Optional',
          icon: Icons.directions_car_outlined,
          selected: d.licenseFront,
          onTap: () => _pick((p) => d.licenseFrontPath = p),
        ),
        DocTile(
          title: 'Driving licence — back',
          subtitle: 'Optional',
          icon: Icons.directions_car_outlined,
          selected: d.licenseBack,
          onTap: () => _pick((p) => d.licenseBackPath = p),
        ),
        DocTile(
          title: 'Profile photo',
          subtitle: 'Required · passport size',
          icon: Icons.person_outline_rounded,
          selected: d.profilePhoto,
          onTap: () => _pick((p) => d.profilePhotoPath = p),
        ),
      ],
    );
  }
}
