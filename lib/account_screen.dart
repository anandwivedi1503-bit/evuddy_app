import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'api/evuddy_api.dart';
import 'deposit_wallet_screen.dart';
import 'invest_screen.dart';
import 'open_link.dart';
import 'state/registration_draft.dart';
import 'theme/evuddy.dart';
import 'widgets/chrome.dart';
import 'widgets/promo.dart';

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

  @override
  Widget build(BuildContext context) {
    final d = registrationDraft;
    final status = !d.phoneVerified
        ? 'Not signed in'
        : d.canBook
            ? 'Approved · Book EV open'
            : (d.approvalStatus.isEmpty ? 'KYC pending' : d.approvalStatus);
    return AuthScreen(
      showBack: false,
      kicker: 'Account',
      title: d.fullName.isEmpty ? 'Your EVUDDY' : d.fullName,
      subtitle: status,
      footer: EvuddyGhostButton(
        label: 'Log out on this phone',
        onPressed: () {
          d.clearSession();
          widget.onLoggedOut?.call();
        },
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
        if (d.activeBooking != null) ...[
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
                  Text('PICKUP OTP', style: Theme.of(context).textTheme.labelSmall),
                  SelectableText(
                    d.activeBooking!.pickupOtp,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 4,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
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
                        'Hold only · no recharge',
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
          onTap: () => Navigator.push(context, evuddyRoute(const InvestScreen())),
          child: const ScenePhoto(
            asset: Evuddy.investPosterAsset,
            height: 280,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 14),
        EvuddyButton(
          label: 'Investment plans',
          onPressed: () => Navigator.push(context, evuddyRoute(const InvestScreen())),
        ),
        const SizedBox(height: 10),
        EvuddyGhostButton(
          label: 'Call helpdesk 24×7',
          onPressed: dialHelpdesk,
        ),
        const SizedBox(height: 14),
        const InfoNote(
          text:
              'OTP uses Firebase on evuddy.com. We never store your SMS inbox. Helpdesk · helpdesk@kebuone.in · +91 8726006512',
        ),
      ],
    );
  }
}
