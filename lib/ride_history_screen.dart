import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'api/evuddy_api.dart';
import 'receipt_detail_screen.dart';
import 'state/registration_draft.dart';
import 'theme/evuddy.dart';
import 'widgets/booking_ui.dart';
import 'widgets/chrome.dart';

class RideHistoryScreen extends StatefulWidget {
  const RideHistoryScreen({super.key});

  @override
  State<RideHistoryScreen> createState() => _RideHistoryScreenState();
}

class _RideHistoryScreenState extends State<RideHistoryScreen> {
  List<RideHistoryItem> rides = [];
  List<PaymentReceipt> receipts = [];
  String rideCursor = '';
  String receiptCursor = '';
  bool ridesHaveMore = false;
  bool receiptsHaveMore = false;
  bool loadingMoreRides = false;
  bool loadingMoreReceipts = false;
  bool _loadedOlderRides = false;
  bool _loadedOlderReceipts = false;
  bool loading = true;
  String? error;
  String? reviewNote;
  bool busy = false;
  RideHistoryItem? rating;
  int stars = 5;
  final comment = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    comment.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    final token = await registrationDraft.freshToken(force: true);
    if (token == null) {
      setState(() {
        loading = false;
        error = 'Confirm your registered mobile to load history from evuddy.com.';
      });
      return;
    }
    try {
      final historyPage = await EvuddyApi.bookingHistoryPage(token);
      ApiListPage<PaymentReceipt>? receiptPage;
      try {
        receiptPage = await EvuddyApi.myReceiptsPage(token);
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        final firstRideIds = historyPage.items.map((item) => item.bookingId).toSet();
        rides = _loadedOlderRides
            ? [
                ...historyPage.items,
                ...rides.where((item) => !firstRideIds.contains(item.bookingId)),
              ]
            : historyPage.items;
        if (!_loadedOlderRides) rideCursor = historyPage.nextCursor;
        ridesHaveMore = _loadedOlderRides ? ridesHaveMore : historyPage.hasMore;
        if (receiptPage != null) {
          final firstReceiptIds = receiptPage.items.map((item) => item.transactionId).toSet();
          receipts = _loadedOlderReceipts
              ? [
                  ...receiptPage.items,
                  ...receipts.where((item) => !firstReceiptIds.contains(item.transactionId)),
                ]
              : receiptPage.items;
          if (!_loadedOlderReceipts) receiptCursor = receiptPage.nextCursor;
          receiptsHaveMore = _loadedOlderReceipts ? receiptsHaveMore : receiptPage.hasMore;
        }
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = e.toString();
      });
    }
  }

  Future<void> _loadOlderRides() async {
    if (loadingMoreRides || !ridesHaveMore || rideCursor.isEmpty) return;
    setState(() => loadingMoreRides = true);
    try {
      final token = await registrationDraft.freshToken(force: true);
      if (token == null) throw ApiException('Sign in again to load older rides.');
      final page = await EvuddyApi.bookingHistoryPage(token, cursor: rideCursor);
      if (!mounted) return;
      setState(() {
        final known = rides.map((item) => item.bookingId).toSet();
        rides = [...rides, ...page.items.where((item) => !known.contains(item.bookingId))];
        rideCursor = page.nextCursor;
        ridesHaveMore = page.hasMore;
        _loadedOlderRides = true;
      });
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loadingMoreRides = false);
    }
  }

  Future<void> _loadOlderReceipts() async {
    if (loadingMoreReceipts || !receiptsHaveMore || receiptCursor.isEmpty) return;
    setState(() => loadingMoreReceipts = true);
    try {
      final token = await registrationDraft.freshToken(force: true);
      if (token == null) throw ApiException('Sign in again to load older receipts.');
      final page = await EvuddyApi.myReceiptsPage(token, cursor: receiptCursor);
      if (!mounted) return;
      setState(() {
        final known = receipts.map((item) => item.transactionId).toSet();
        receipts = [...receipts, ...page.items.where((item) => !known.contains(item.transactionId))];
        receiptCursor = page.nextCursor;
        receiptsHaveMore = page.hasMore;
        _loadedOlderReceipts = true;
      });
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loadingMoreReceipts = false);
    }
  }

  Future<void> _saveReview() async {
    final item = rating;
    if (item == null) return;
    final text = comment.text.trim();
    if (text.isNotEmpty && text.length < 8) {
      setState(() => reviewNote = 'Write at least 8 characters, or leave it empty.');
      return;
    }
    setState(() {
      busy = true;
      reviewNote = null;
    });
    try {
      final token = await registrationDraft.freshToken(force: true);
      if (token == null) throw ApiException('Sign in again to save the review.');
      await EvuddyApi.submitReview(
        idToken: token,
        bookingId: item.bookingId,
        stars: stars,
        comment: text,
      );
      comment.clear();
      rating = null;
      await _load();
      if (!mounted) return;
      setState(() {
        busy = false;
        reviewNote = 'Review saved on the same rider file as evuddy.com.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        busy = false;
        reviewNote = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BookStage(
      kicker: 'History',
      title: 'Rides and receipts',
      subtitle: 'Completed and cancelled bookings from the same MongoDB as evuddy.com.',
      error: error,
      footer: EvuddyButton(
        sun: true,
        label: loading ? 'Loading…' : 'Refresh from evuddy.com',
        busy: loading,
        onPressed: loading ? null : _load,
      ),
      children: [
        if (reviewNote != null) InfoNote(text: reviewNote!),
        if (reviewNote != null) const SizedBox(height: 12),
        if (!loading && rides.isEmpty && receipts.isEmpty)
          const InfoNote(text: 'No completed rides yet. After you return a scooter, it appears here and on the website account.'),
        for (final ride in rides)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ride.bookingId,
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${ride.rentalMode} · ${ride.rideStatus} · ${CatalogRates.inr(ride.receivedAmount)}',
                    style: GoogleFonts.plusJakartaSans(color: Evuddy.muted, fontWeight: FontWeight.w600),
                  ),
                  if (ride.vehicleId.isNotEmpty || ride.hub.isNotEmpty)
                    Text(
                      [ride.vehicleId, ride.hub, ride.city].where((s) => s.isNotEmpty).join(' · '),
                      style: GoogleFonts.plusJakartaSans(color: Evuddy.muted, fontSize: 13),
                    ),
                  if (ride.reviewStars != null)
                    Text('You rated ${ride.reviewStars}/5', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
                  if (ride.canReview) ...[
                    const SizedBox(height: 8),
                    EvuddyGhostButton(
                      label: rating?.bookingId == ride.bookingId ? 'Cancel rating' : 'Rate this ride',
                      onPressed: () => setState(() {
                        rating = rating?.bookingId == ride.bookingId ? null : ride;
                        stars = 5;
                      }),
                    ),
                  ],
                  if (rating?.bookingId == ride.bookingId) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        for (var i = 1; i <= 5; i++)
                          IconButton(
                            onPressed: () => setState(() => stars = i),
                            icon: Icon(
                              i <= stars ? Icons.star_rounded : Icons.star_outline_rounded,
                              color: const Color(0xFFF59E0B),
                            ),
                          ),
                      ],
                    ),
                    TextField(
                      controller: comment,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Optional comment',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    EvuddyButton(
                      sun: true,
                      label: busy ? 'Saving…' : 'Save review',
                      busy: busy,
                      onPressed: busy ? null : _saveReview,
                    ),
                  ],
                ],
              ),
            ),
          ),
        if (ridesHaveMore)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: EvuddyGhostButton(
              label: loadingMoreRides ? 'Loading older rides…' : 'Load older rides',
              onPressed: loadingMoreRides ? null : _loadOlderRides,
            ),
          ),
        if (receipts.isNotEmpty) ...[
          const SectionLabel('Payment receipts · download PDF'),
          const SizedBox(height: 10),
          for (final rec in receipts)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      CatalogRates.inr(rec.amount),
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 18),
                    ),
                    Text(
                      '${rec.paymentMethod.isEmpty ? "Razorpay UPI / card" : rec.paymentMethod} · Booking ${rec.bookingId}',
                      style: GoogleFonts.plusJakartaSans(color: Evuddy.muted, fontWeight: FontWeight.w600),
                    ),
                    if (rec.invoiceNumber.isNotEmpty || rec.transactionId.isNotEmpty)
                      Text(
                        [
                          if (rec.invoiceNumber.isNotEmpty) 'Invoice ${rec.invoiceNumber}',
                          if (rec.transactionId.isNotEmpty) 'Txn ${rec.transactionId}',
                        ].join(' · '),
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Evuddy.muted),
                      ),
                    const SizedBox(height: 10),
                    EvuddyGhostButton(
                      label: 'View details & download PDF',
                      onPressed: () => Navigator.push(
                        context,
                        evuddyRoute(ReceiptDetailScreen(receipt: rec)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (receiptsHaveMore)
            EvuddyGhostButton(
              label: loadingMoreReceipts ? 'Loading older receipts…' : 'Load older receipts',
              onPressed: loadingMoreReceipts ? null : _loadOlderReceipts,
            ),
        ],
      ],
    );
  }
}
