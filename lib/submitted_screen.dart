import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'shell.dart';
import 'state/registration_draft.dart';
import 'theme/evuddy.dart';
import 'widgets/chrome.dart';

class SubmittedScreen extends StatefulWidget {
  const SubmittedScreen({super.key});

  @override
  State<SubmittedScreen> createState() => _SubmittedScreenState();
}

class _SubmittedScreenState extends State<SubmittedScreen>
    with WidgetsBindingObserver {
  Timer? _poll;
  bool _checking = false;
  String? _note;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check();
    _poll = Timer.periodic(const Duration(seconds: 5), (_) => _check());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _check() async {
    if (_checking) return;
    setState(() => _checking = true);
    final lookup = await registrationDraft.refreshFromServer();
    if (!mounted) return;
    setState(() => _checking = false);
    if (registrationDraft.isRejected) {
      setState(() => _note = lookup?.message ?? 'This registration was rejected.');
      return;
    }
    if (registrationDraft.canBook) {
      _openBooking();
    }
  }

  void _openBooking() {
    _poll?.cancel();
    registrationDraft.jumpToTab(1);
    Navigator.of(context).pushAndRemoveUntil(
      evuddyRoute(const RiderShell(startIndex: 1)),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = registrationDraft;
    final first = d.fullName.split(' ').first;
    final approved = d.canBook;
    final status = d.approvalStatus.isEmpty ? 'Under Review' : d.approvalStatus;
    final title = approved
        ? (first.isEmpty ? 'You’re approved.' : 'You’re approved, $first.')
        : (first.isEmpty ? 'You’re in.' : 'You’re in, $first.');
    return AuthScreen(
      showBack: false,
      kicker: 'Application',
      title: title,
      subtitle: approved
          ? 'Admin approved this number. Opening Normal booking and Rent to Own.'
          : 'KYC is with ops. This screen updates automatically when the admin approves you — then Normal and Rent to Own unlock.',
      footer: Column(
        children: [
          EvuddyButton(
            label: approved
                ? 'Book EV now'
                : (_checking ? 'Checking approval…' : 'Check approval now'),
            busy: _checking && !approved,
            icon: approved ? Icons.electric_moped_rounded : Icons.refresh_rounded,
            onPressed: approved ? _openBooking : _check,
          ),
          const SizedBox(height: 10),
          EvuddyGhostButton(
            label: 'Back to home',
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                evuddyRoute(const RiderShell()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: const BoxDecoration(
            color: Evuddy.greenSoft,
            shape: BoxShape.circle,
          ),
          child: Icon(
            approved ? Icons.verified_rounded : Icons.hourglass_top_rounded,
            size: 36,
            color: Evuddy.green,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          d.phoneDisplay,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: Evuddy.ink,
          ),
        ),
        if (d.riderId != null) ...[
          const SizedBox(height: 8),
          Text(
            'Rider ID ${d.riderId}',
            style: GoogleFonts.plusJakartaSans(color: Evuddy.muted, fontSize: 13),
          ),
        ],
        const SizedBox(height: 8),
        Text(
          'Status · $status',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            color: approved ? Evuddy.greenDeep : Evuddy.muted,
          ),
        ),
        if (!approved) ...[
          const SizedBox(height: 16),
          const InfoNote(
            text:
                'Keep the app open or pull back later. The same second ops taps Approve on evuddy.com, Book EV opens here.',
          ),
        ],
        if (_note != null) ...[
          const SizedBox(height: 12),
          InfoNote(text: _note!),
        ],
      ],
    );
  }
}
