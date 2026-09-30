import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../api/evuddy_api.dart';
import '../state/registration_draft.dart';
import '../theme/evuddy.dart';
import 'chrome.dart';

const ticketCategories = <String, String>{
  'BOOKING_ISSUE': 'Booking / general',
  'UNLOCK_ISSUE': 'Unlock / pickup OTP',
  'VEHICLE_BREAKDOWN': 'Scooter breakdown',
  'BATTERY_ISSUE': 'Battery / range / swap',
  'PAYMENT_ISSUE': 'Payment',
  'REFUND_REQUEST': 'Deposit refund',
  'OVERCHARGING': 'Overcharging',
  'OTHER': 'Other',
};

/// Same POST /api/tickets + GET /api/tickets/mine flow as evuddy.com Book EV.
class SupportTicketsCard extends StatefulWidget {
  const SupportTicketsCard({
    super.key,
    this.bookingId,
    this.rideStatus = '',
    this.requireBooking = false,
  });

  final String? bookingId;
  final String rideStatus;
  final bool requireBooking;

  @override
  State<SupportTicketsCard> createState() => _SupportTicketsCardState();
}

class _SupportTicketsCardState extends State<SupportTicketsCard> {
  final help = TextEditingController();
  String category = 'BOOKING_ISSUE';
  String? status;
  bool loading = false;
  bool sending = false;
  List<SupportTicket> tickets = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    help.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final token = await registrationDraft.freshToken();
    if (token == null || token.isEmpty) return;
    setState(() => loading = true);
    try {
      final rows = await EvuddyApi.myTickets(token);
      if (!mounted) return;
      setState(() {
        tickets = rows;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        status = e.toString();
      });
    }
  }

  Future<void> _send() async {
    setState(() => status = null);
    final description = help.text.trim();
    if (description.length < 10) {
      setState(() => status = 'Describe the issue in at least 10 characters.');
      return;
    }
    final token = await registrationDraft.freshToken();
    final d = registrationDraft;
    final bookingId = (widget.bookingId ?? d.activeBooking?.bookingId ?? '').trim();
    if (token == null || token.isEmpty) {
      setState(() => status = 'Sign in first.');
      return;
    }
    if (widget.requireBooking && bookingId.isEmpty) {
      setState(() => status = 'Sign in and complete booking first.');
      return;
    }
    final ride = widget.rideStatus.isNotEmpty
        ? widget.rideStatus
        : (d.activeBooking?.rideStatus ?? '');
    final prefixed = ride.toLowerCase() == 'in ride' ? 'During ride: $description' : description;
    setState(() => sending = true);
    try {
      await EvuddyApi.createTicket(
        idToken: token,
        ticketId: bookingId.isEmpty
            ? 'APP-${DateTime.now().millisecondsSinceEpoch}'
            : 'BK-${DateTime.now().millisecondsSinceEpoch}',
        userId: d.phone.isNotEmpty ? d.phone : (d.riderId ?? 'rider'),
        bookingId: bookingId.isEmpty ? null : bookingId,
        category: category,
        description: prefixed,
      );
      help.clear();
      final rows = await EvuddyApi.myTickets(token);
      if (!mounted) return;
      setState(() {
        sending = false;
        tickets = rows;
        status =
            'Support ticket sent. You can track status below. Hub staff see it on Support.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        sending = false;
        status = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.requireBooking ? 'Need help with this booking?' : 'Support tickets',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Use this during pickup or mid-ride: unlock, breakdown, battery, payment. Hub staff see it immediately and you see their reply below.',
            style: GoogleFonts.plusJakartaSans(
              color: Evuddy.muted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          DropdownMenu<String>(
            initialSelection: category,
            expandedInsets: EdgeInsets.zero,
            dropdownMenuEntries: [
              for (final e in ticketCategories.entries)
                DropdownMenuEntry(value: e.key, label: e.value),
            ],
            onSelected: (v) {
              if (v == null) return;
              setState(() => category = v);
            },
          ),
          const SizedBox(height: 10),
          TextField(
            controller: help,
            maxLines: 3,
            maxLength: 500,
            decoration: InputDecoration(
              hintText: 'What happened? Example: scooter stopped, battery died, puncture...',
              filled: true,
              fillColor: Evuddy.paper,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SizedBox(height: 8),
          EvuddyButton(
            label: sending ? 'Sending...' : 'Send to support',
            icon: Icons.support_agent_rounded,
            onPressed: sending ? null : _send,
            busy: sending,
          ),
          if (status != null) ...[
            const SizedBox(height: 10),
            Text(
              status!,
              style: GoogleFonts.plusJakartaSans(
                color: Evuddy.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (loading) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(),
          ],
          if (tickets.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Your tickets',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            for (final t in tickets)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Evuddy.line),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${t.ticketId} · ${t.status} · ${t.category.replaceAll('_', ' ')}',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
                      ),
                      if (t.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          t.description,
                          style: GoogleFonts.plusJakartaSans(color: Evuddy.muted, fontSize: 13),
                        ),
                      ],
                      if (t.adminRemarks.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Hub: ${t.adminRemarks}',
                          style: GoogleFonts.plusJakartaSans(
                            color: Evuddy.greenDeep,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
