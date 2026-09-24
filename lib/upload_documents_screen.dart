import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'api/evuddy_api.dart';
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
  String? progress;
  bool busy = false;
  final _picker = ImagePicker();

  Future<void> _pick(void Function(String path) assign) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Add photo',
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Evuddy.ink,
                      ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined, color: Evuddy.greenDeep),
                  title: const Text('Camera'),
                  onTap: () => Navigator.pop(ctx, ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined, color: Evuddy.greenDeep),
                  title: const Text('Gallery'),
                  onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (source == null || !mounted) return;
    final shot = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1600,
      requestFullMetadata: false,
    );
    if (shot == null) return;
    setState(() {
      assign(shot.path);
      error = null;
    });
  }

  Future<String> _up(String? path, String label, String filename) async {
    if (path == null) return '';
    setState(() => progress = 'Uploading $label…');
    final token = await _token();
    return EvuddyApi.uploadFile(
      file: File(path),
      idToken: token,
      filename: filename,
    );
  }

  Future<String> _token() async {
    final stored = registrationDraft.firebaseIdToken;
    if (stored != null && stored.isNotEmpty) return stored;
    throw ApiException('Phone OTP expired. Go back and verify again.');
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
      final front = await _up(d.aadhaarFrontPath, 'Aadhaar front', 'aadhaar-front');
      final back = await _up(d.aadhaarBackPath, 'Aadhaar back', 'aadhaar-back');
      final lf = await _up(d.licenseFrontPath, 'licence front', 'dl-front');
      final lb = await _up(d.licenseBackPath, 'licence back', 'dl-back');
      final photo = await _up(d.profilePhotoPath, 'profile photo', 'profile');
      setState(() => progress = 'Creating your rider account…');
      final token = await _token();
      final body = <String, dynamic>{
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
        'profilePhotoUrl': photo,
        'instagramId': d.instagramId,
        'facebookId': d.facebookId,
        'comingThrough': d.comingThrough,
        'reference1Name': d.reference1Name,
        'reference1Phone': d.reference1Phone,
        'reference2Name': d.reference2Name,
        'reference2Phone': d.reference2Phone,
      };
      if (lf.isNotEmpty) body['licenseFrontUrl'] = lf;
      if (lb.isNotEmpty) body['licenseBackUrl'] = lb;
      final result = await EvuddyApi.createRider(body);
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
      subtitle: 'Aadhaar front, back and a clear profile photo. Camera or gallery.',
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
          subtitle: 'Required · face clearly visible',
          icon: Icons.person_outline_rounded,
          selected: d.profilePhoto,
          onTap: () => _pick((p) => d.profilePhotoPath = p),
        ),
      ],
    );
  }
}
