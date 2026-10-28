import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'api/evuddy_api.dart';
import 'api/fleet_calculator.dart';
import 'app_version.dart';
import 'confirm_mobile_screen.dart';
import 'deposit_wallet_screen.dart';
import 'rider_refund_screen.dart';
import 'security_alerts_screen.dart';
import 'fleet_calculator_screen.dart';
import 'invest_screen.dart';
import 'login_screen.dart';
import 'open_link.dart';
import 'ride_history_screen.dart';
import 'ride_ready_screen.dart';
import 'state/registration_draft.dart';
import 'submitted_screen.dart';
import 'theme/evuddy.dart';
import 'widgets/chrome.dart';
import 'widgets/promo.dart';
import 'widgets/scenes.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key, this.onLoggedOut});
  final VoidCallback? onLoggedOut;

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  bool checking = false;

  @override
  void initState() {
    super.initState();
    riderSessionTick.addListener(_tick);
    if (registrationDraft.phoneVerified) {
      _refresh();
    }
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
    setState(() => checking = true);
    await registrationDraft.refreshFromServer();
    if (!mounted) return;
    setState(() => checking = false);
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text(
          'You will need OTP on this registered mobile again — same as evuddy.com.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Stay')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await registrationDraft.logout();
    if (!mounted) return;
    widget.onLoggedOut?.call();
    Navigator.of(context, rootNavigator: true).popUntil((r) => r.isFirst);
    if (mounted) setState(() {});
  }

  Widget _logoutButton({bool compact = false}) {
    if (compact) {
      return IconButton(
        tooltip: 'Log out',
        onPressed: _logout,
        icon: const Icon(Icons.logout_rounded, color: Evuddy.magenta),
      );
    }
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: _logout,
        style: OutlinedButton.styleFrom(
          foregroundColor: Evuddy.magenta,
          side: const BorderSide(color: Color(0xFFF9A8D4)),
          backgroundColor: const Color(0xFFFDF2F8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Text(
          'Log out',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  Widget _footer(RegistrationDraft d) {
    if (!d.phoneVerified) {
      return EvuddyButton(
        label: 'Confirm mobile',
        onPressed: () => Navigator.push(context, evuddyRoute(const ConfirmMobileScreen())),
      );
    }
    if (d.hasLiveBooking) {
      return EvuddyButton(
        label: 'Open booking ${d.activeBooking!.bookingId}',
        onPressed: () => Navigator.push(context, evuddyRoute(const RideReadyScreen())),
      );
    }
    if (d.canBook) {
      return EvuddyButton(
        label: 'Book an EV',
        onPressed: () {
          registrationDraft.jumpToTab(1);
        },
      );
    }
    if (d.isPendingKyc) {
      return EvuddyButton(
        label: 'View KYC status',
        onPressed: () => Navigator.push(context, evuddyRoute(const SubmittedScreen())),
      );
    }
    return EvuddyButton(
      label: 'Complete registration',
      onPressed: () => Navigator.push(context, evuddyRoute(const LoginScreen())),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = registrationDraft;
    final status = !d.phoneVerified
        ? 'Confirm the same mobile as evuddy.com'
        : d.canBook
            ? 'Approved · ready to book'
            : (d.approvalStatus.isEmpty ? 'KYC pending' : d.approvalStatus);
    return AuthScreen(
      showBack: false,
      kicker: 'Account',
      title: d.fullName.isEmpty ? 'Your EVUDDY' : d.fullName,
      subtitle: status,
      headerTrailing: d.phoneVerified ? _logoutButton(compact: true) : null,
      footer: Column(
        children: [
          _footer(d),
          if (d.phoneVerified) ...[
            const SizedBox(height: 10),
            _logoutButton(),
          ],
        ],
      ),
      children: [
        if (d.phoneVerified)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: EvuddyGhostButton(
              label: checking ? 'Refreshing…' : 'Refresh approval & booking',
              onPressed: checking ? null : _refresh,
            ),
          ),
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                d.phoneDisplay.isEmpty ? 'No number yet' : d.phoneDisplay,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                d.email.isEmpty ? 'Complete KYC to unlock hubs' : d.email,
                style: GoogleFonts.plusJakartaSans(color: Evuddy.muted),
              ),
              if (d.riderId != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Rider ${d.riderId} · $status',
                  style: GoogleFonts.plusJakartaSans(
                    color: d.canBook ? Evuddy.greenDeep : Evuddy.muted,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (d.hasLiveBooking && d.activeBooking != null) ...[
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Open booking ${d.activeBooking!.bookingId}',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Remaining ₹${d.activeBooking!.due.toStringAsFixed(0)} · ${d.activeBooking!.paymentStatus}',
                  style: GoogleFonts.plusJakartaSans(color: Evuddy.muted),
                ),
                if (d.activeBooking!.hasPickupOtp) ...[
                  const SizedBox(height: 10),
                  OtpReveal(
                    label: 'PICKUP OTP',
                    code: d.activeBooking!.pickupOtp,
                    hint: 'Yard enters this to unlock the scooter.',
                  ),
                ],
                if (d.activeBooking!.rideEndOtp.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  OtpReveal(
                    label: 'RIDE END OTP',
                    code: d.activeBooking!.rideEndOtp,
                    hint: 'Yard enters this to complete the ride.',
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
        GestureDetector(
          onTap: d.phoneVerified
              ? () => Navigator.push(context, evuddyRoute(const RideHistoryScreen()))
              : null,
          child: SurfaceCard(
            child: Row(
              children: [
                const Icon(Icons.history_rounded, color: Evuddy.greenDeep),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('RIDES & RECEIPTS', style: Theme.of(context).textTheme.labelSmall),
                      const SizedBox(height: 4),
                      Text(
                        'Same booking history as evuddy.com',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        'Download PDF receipts, rate rides, same data as evuddy.com.',
                        style: GoogleFonts.plusJakartaSans(color: Evuddy.muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Evuddy.muted),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: d.phoneVerified
              ? () => Navigator.push(context, evuddyRoute(const SecurityAlertsScreen()))
              : null,
          child: SurfaceCard(
            child: Row(
              children: [
                const Icon(Icons.emergency_outlined, color: Evuddy.magenta),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('TRIP SAFETY & ALERTS', style: Theme.of(context).textTheme.labelSmall),
                      const SizedBox(height: 4),
                      Text(
                        'Siren timer · GPS · booking end reminders',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        'For riders on this phone. Not the EVUDDY admin CRM.',
                        style: GoogleFonts.plusJakartaSans(color: Evuddy.muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Evuddy.muted),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        const InfoNote(
          text:
              'EVUDDY admin CRM, live fleet IoT map, finance desks, and rider phone GPS tracking for ops are on evuddy.com admin — staff log in on the web, not through the rider app.',
        ),
        const SizedBox(height: 14),
        const TrustStrip(),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: () => Navigator.push(context, evuddyRoute(const DepositWalletScreen())),
          child: SurfaceCard(
            child: Row(
              children: [
                const Icon(Icons.account_balance_wallet_outlined, color: Evuddy.greenDeep),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('SECURITY DEPOSIT', style: Theme.of(context).textTheme.labelSmall),
                      const SizedBox(height: 4),
                      Text(
                        '${CatalogRates.inr(d.depositHeld)} · ${d.depositLabel}',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        'Wallet ${CatalogRates.inr(d.walletAvailable)} · deposit hold ${CatalogRates.inr(d.depositHeld)}',
                        style: GoogleFonts.plusJakartaSans(color: Evuddy.muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Evuddy.muted),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        const OfferAdCarousel(),
        const SizedBox(height: 14),
        EvuddyButton(
          label: 'Investment plans',
          onPressed: () => Navigator.push(context, evuddyRoute(const InvestScreen())),
        ),
        const SizedBox(height: 10),
        EvuddyGhostButton(
          label: 'Fleet calculator',
          onPressed: () => Navigator.push(context, evuddyRoute(const FleetCalculatorScreen())),
        ),
        const SizedBox(height: 10),
        EvuddyGhostButton(
          label: 'Business planner',
          onPressed: () => Navigator.push(
            context,
            evuddyRoute(
              const FleetCalculatorScreen(
                audience: FleetAudience.planner,
                lockPlanner: false,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        EvuddyGhostButton(
          label: 'Call helpdesk 24×7',
          onPressed: dialHelpdesk,
        ),
        const SizedBox(height: 14),
        const InfoNote(
          text:
              'Same screens as evuddy.com Book EV: confirm mobile → OTP → book if approved. OTP uses Firebase. Helpdesk · helpdesk@kebuone.in · +91 8726006512',
        ),
        const SizedBox(height: 10),
        Text(
          evuddyVersionLabel,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Evuddy.muted,
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}
