import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import 'api/evuddy_api.dart';
import 'api/firebase_phone.dart';
import 'services/user_facing_error.dart';
import 'state/registration_draft.dart';
import 'theme/evuddy.dart';
import 'widgets/chrome.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  late final TextEditingController name;
  late final TextEditingController email;
  late final TextEditingController instagram;
  late final TextEditingController facebook;
  String? photoUrl;
  String? localPhotoPath;
  bool saving = false;
  bool uploading = false;
  String? error;
  String? ok;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final d = registrationDraft;
    name = TextEditingController(text: d.fullName);
    email = TextEditingController(text: d.email);
    instagram = TextEditingController(text: d.instagramId);
    facebook = TextEditingController(text: d.facebookId);
    photoUrl = d.profilePhotoUrl.isNotEmpty ? d.profilePhotoUrl : null;
    localPhotoPath = d.profilePhotoPath;
  }

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    instagram.dispose();
    facebook.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
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
                  'Profile photo',
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
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1200,
      imageQuality: 85,
      requestFullMetadata: false,
    );
    if (picked == null) return;
    setState(() {
      uploading = true;
      error = null;
      localPhotoPath = picked.path;
    });
    try {
      final token = await registrationDraft.freshToken(force: true);
      if (token == null) throw ApiException('Sign in again with OTP.');
      final url = await EvuddyApi.uploadFile(
        file: File(picked.path),
        idToken: token,
        filename: 'profile',
      );
      if (!mounted) return;
      setState(() {
        uploading = false;
        photoUrl = url;
        registrationDraft.profilePhotoUrl = url;
        registrationDraft.profilePhotoPath = picked.path;
      });
      await registrationDraft.persist();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        uploading = false;
        error = userFacingError(e, fallback: 'Could not upload photo.');
      });
    }
  }

  Future<void> _save() async {
    final riderId = registrationDraft.riderId;
    if (riderId == null || riderId.isEmpty) {
      setState(() => error = 'Complete registration before editing profile.');
      return;
    }
    final fullName = name.text.trim();
    final mail = email.text.trim();
    if (fullName.length < 2) {
      setState(() => error = 'Enter your full name.');
      return;
    }
    if (!mail.contains('@')) {
      setState(() => error = 'Enter a valid email for receipts and alerts.');
      return;
    }
    setState(() {
      saving = true;
      error = null;
      ok = null;
    });
    try {
      final token = await registrationDraft.freshToken(force: true);
      if (token == null || EvuddyFirebase.jwtExpired(token)) {
        setState(() {
          saving = false;
          error = 'Session expired. Log in with OTP again.';
        });
        return;
      }
      await EvuddyApi.updateRiderProfile(
        idToken: token,
        riderId: riderId,
        fullName: fullName,
        email: mail,
        profilePhotoUrl: photoUrl,
        instagramId: instagram.text.trim(),
        facebookId: facebook.text.trim(),
      );
      registrationDraft
        ..fullName = fullName
        ..email = mail
        ..instagramId = instagram.text.trim()
        ..facebookId = facebook.text.trim();
      if (photoUrl != null && photoUrl!.isNotEmpty) {
        registrationDraft.profilePhotoUrl = photoUrl!;
      }
      if (localPhotoPath != null) {
        registrationDraft.profilePhotoPath = localPhotoPath;
      }
      await registrationDraft.persist();
      if (!mounted) return;
      setState(() {
        saving = false;
        ok =
            'Profile saved on evuddy.com. Photo and name show in CRM and on your account.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        saving = false;
        error = userFacingError(e, fallback: 'Could not save profile. Try again.');
      });
    }
  }

  Widget _avatar() {
    ImageProvider? img;
    if (localPhotoPath != null && localPhotoPath!.isNotEmpty) {
      img = FileImage(File(localPhotoPath!));
    } else if (photoUrl != null && photoUrl!.startsWith('http')) {
      img = NetworkImage(photoUrl!);
    }
    final initials = name.text.trim().isEmpty
        ? '?'
        : name.text.trim().substring(0, 1).toUpperCase();
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        CircleAvatar(
          radius: 52,
          backgroundColor: Evuddy.greenSoft,
          backgroundImage: img,
          child: img == null
              ? Text(
                  initials,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Evuddy.greenDeep,
                  ),
                )
              : null,
        ),
        Material(
          color: Evuddy.rapidoYellow,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: uploading ? null : _pickPhoto,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: uploading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.camera_alt_rounded, size: 20, color: Evuddy.ink),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthScreen(
      kicker: 'Profile',
      title: 'Edit your profile',
      subtitle:
          'Same photo as KYC step 4. Camera or gallery — syncs to evuddy.com CRM.',
      error: error,
      footer: EvuddyButton(
        label: saving ? 'Saving…' : 'Save profile',
        busy: saving,
        onPressed: saving ? null : _save,
      ),
      children: [
        if (ok != null) ...[
          InfoNote(text: ok!),
          const SizedBox(height: 14),
        ],
        Center(child: _avatar()),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Tap camera — same as registration face photo',
            style: GoogleFonts.plusJakartaSans(color: Evuddy.muted, fontSize: 12),
          ),
        ),
        const SizedBox(height: 18),
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('REGISTERED MOBILE', style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: 6),
              Text(
                registrationDraft.phoneDisplay,
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 17),
              ),
              const SizedBox(height: 4),
              Text(
                'Used for OTP login and payment SMS',
                style: GoogleFonts.plusJakartaSans(color: Evuddy.muted, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: name,
          textCapitalization: TextCapitalization.words,
          autofillHints: const [AutofillHints.name],
          decoration: const InputDecoration(labelText: 'Full name'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: email,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          decoration: const InputDecoration(labelText: 'Email (receipts & updates)'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: instagram,
          decoration: const InputDecoration(
            labelText: 'Instagram (optional)',
            prefixText: '@',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: facebook,
          decoration: const InputDecoration(labelText: 'Facebook profile (optional)'),
        ),
      ],
    );
  }
}
