import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'api/evuddy_api.dart';
import 'deposit_wallet_screen.dart';
import 'profile_edit_screen.dart';
import 'ride_history_screen.dart';
import 'ride_ready_screen.dart';
import 'security_alerts_screen.dart';
import 'services/rider_safety_tracker.dart';
import 'services/security_alert_hub.dart';
import 'services/trip_countdown_store.dart';
import 'state/registration_draft.dart';
import 'theme/evuddy.dart';
import 'widgets/chrome.dart';

/// Premium-style rider hub: photo, stats, live trip, recent rides, updates.
class RiderProfileScreen extends StatefulWidget {
  const RiderProfileScreen({super.key});

  @override
  State<RiderProfileScreen> createState() => _RiderProfileScreenState();
}

class _RiderProfileScreenState extends State<RiderProfileScreen> {
  List<RideHistoryItem> rides = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    riderSessionTick.addListener(_tick);
    _refresh();
  }

  void _tick() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    riderSessionTick.removeListener(_tick);
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() {
      loading = true;
      error = null;
    });
    await registrationDraft.refreshFromServer(forceToken: true);
    final token = await registrationDraft.freshToken(force: true);
    if (token == null) {
      setState(() {
        loading = false;
        error = 'Confirm mobile with OTP to load your evuddy.com profile.';
      });
      return;
    }
    try {
      final history = await EvuddyApi.bookingHistory(token);
      if (!mounted) return;
      setState(() {
        rides = history;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = 'Could not load ride history.';
      });
    }
  }

  ImageProvider? _photo(RegistrationDraft d) {
    if (d.profilePhotoPath != null && d.profilePhotoPath!.isNotEmpty) {
      return FileImage(File(d.profilePhotoPath!));
    }
    if (d.profilePhotoUrl.isNotEmpty && d.profilePhotoUrl.startsWith('http')) {
      return NetworkImage(d.profilePhotoUrl);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final d = registrationDraft;
    final active = d.activeBooking;
    final alerts = SecurityAlertHub.instance.all.take(5).toList();
    final gpsOn = RiderSafetyTracker.instance.active;
    final tripLive = TripCountdownStore.instance.active;
    final completedTrips =
        rides.where((r) => r.rideStatus.toLowerCase().contains('complete')).length;

    return AuthScreen(
      showBack: true,
      kicker: 'Rider profile',
      title: d.fullName.isEmpty ? 'Your EVUDDY' : d.fullName,
      subtitle: d.riderId != null ? 'Rider ${d.riderId}' : 'Complete KYC to unlock booking',
      headerTrailing: IconButton(
        tooltip: 'Refresh',
        onPressed: loading ? null : _refresh,
        icon: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.refresh_rounded),
      ),
      footer: EvuddyButton(
        label: 'Edit profile',
        onPressed: () async {
          await Navigator.push(context, evuddyRoute(const ProfileEditScreen()));
          if (mounted) setState(() {});
        },
      ),
      children: [
        if (error != null) ...[
          InfoNote(text: error!),
          const SizedBox(height: 12),
        ],
        SurfaceCard(
          child: Row(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: Evuddy.greenSoft,
                backgroundImage: _photo(d),
                child: _photo(d) == null
                    ? Text(
                        d.fullName.isEmpty ? '?' : d.fullName.substring(0, 1).toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 28,
                          color: Evuddy.greenDeep,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d.phoneDisplay,
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      d.email.isEmpty ? 'Add email for receipts' : d.email,
                      style: GoogleFonts.plusJakartaSans(color: Evuddy.muted, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    _StatusChip(
                      label: d.canBook ? 'Approved · ready to book' : d.approvalStatus,
                      ok: d.canBook,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                label: 'Trips',
                value: '${rides.isEmpty ? '—' : rides.length}',
                sub: completedTrips > 0 ? '$completedTrips completed' : 'Book your first ride',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatTile(
                label: 'Wallet',
                value: CatalogRates.inr(d.walletAvailable),
                sub: d.walletStatus.isEmpty ? 'EVUDDY credit' : d.walletStatus,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatTile(
                label: 'Deposit',
                value: CatalogRates.inr(d.depositHeld),
                sub: d.depositLabel,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (tripLive || gpsOn) ...[
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('LIVE TRIP', style: Theme.of(context).textTheme.labelSmall),
                const SizedBox(height: 8),
                Text(
                  tripLive
                      ? 'Plan ends ${TripCountdownStore.formatDuration(TripCountdownStore.instance.timeUntilEnd ?? Duration.zero)}'
                      : 'Trip safety',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                Text(
                  gpsOn
                      ? 'Phone GPS is shared with EVUDDY ops (like Rapido safety).'
                      : 'Turn on location and start ride for live GPS on admin map.',
                  style: GoogleFonts.plusJakartaSans(color: Evuddy.muted, fontSize: 12),
                ),
                const SizedBox(height: 10),
                EvuddyGhostButton(
                  label: 'Trip safety & alerts',
                  onPressed: () => Navigator.push(
                    context,
                    evuddyRoute(const SecurityAlertsScreen()),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
        if (d.hasLiveBooking && active != null) ...[
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('OPEN BOOKING', style: Theme.of(context).textTheme.labelSmall),
                const SizedBox(height: 6),
                Text(
                  active.bookingId,
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 18),
                ),
                Text(
                  '${active.rideStatus} · ${active.paymentStatus} · due ₹${active.due.toStringAsFixed(0)}',
                  style: GoogleFonts.plusJakartaSans(color: Evuddy.muted),
                ),
                const SizedBox(height: 10),
                EvuddyButton(
                  sun: true,
                  label: 'Open booking workspace',
                  onPressed: () => Navigator.push(
                    context,
                    evuddyRoute(const RideReadyScreen()),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
        Row(
          children: [
            Expanded(
              child: EvuddyGhostButton(
                label: 'Ride history',
                onPressed: () => Navigator.push(
                  context,
                  evuddyRoute(const RideHistoryScreen()),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: EvuddyGhostButton(
                label: 'Deposit',
                onPressed: () => Navigator.push(
                  context,
                  evuddyRoute(const DepositWalletScreen()),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'RECENT RIDES',
          style: Theme.of(context).textTheme.labelSmall,
        ),
        const SizedBox(height: 8),
        if (loading && rides.isEmpty)
          const InfoNote(text: 'Loading rides from evuddy.com…')
        else if (rides.isEmpty)
          const InfoNote(text: 'No rides yet. Book an EV from the bottom tab.')
        else
          ...rides.take(4).map(
                (r) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SurfaceCard(
                    child: Row(
                      children: [
                        const Icon(Icons.electric_moped_rounded, color: Evuddy.greenDeep),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r.bookingId,
                                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
                              ),
                              Text(
                                '${r.rideStatus} · ${r.rentalMode} · ${CatalogRates.inr(r.receivedAmount)}',
                                style: GoogleFonts.plusJakartaSans(color: Evuddy.muted, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
        const SizedBox(height: 14),
        Text(
          'UPDATES & ALERTS',
          style: Theme.of(context).textTheme.labelSmall,
        ),
        const SizedBox(height: 8),
        if (alerts.isEmpty)
          const InfoNote(text: 'Payment receipts, trip reminders, and safety messages appear here.')
        else
          ...alerts.map(
            (a) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a.title,
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      a.body,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(color: Evuddy.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value, required this.sub});
  final String label;
  final String value;
  final String sub;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          Text(
            sub,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(color: Evuddy.muted, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.ok});
  final String label;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: ok ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: ok ? Evuddy.greenDeep : Evuddy.muted,
        ),
      ),
    );
  }
}
