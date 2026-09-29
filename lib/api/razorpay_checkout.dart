import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import '../theme/evuddy.dart';
import 'evuddy_api.dart';

class RazorpayCheckoutPage extends StatefulWidget {
  const RazorpayCheckoutPage({
    super.key,
    required this.order,
    required this.bookingId,
    required this.contact,
    required this.customerName,
    required this.rupees,
    this.email = '',
    this.vehicleId,
  });

  final RazorpayOrder order;
  final String bookingId;
  final String contact;
  final String customerName;
  final double rupees;
  final String email;
  final String? vehicleId;

  @override
  State<RazorpayCheckoutPage> createState() => _RazorpayCheckoutPageState();
}

class _RazorpayCheckoutPageState extends State<RazorpayCheckoutPage> {
  Razorpay? _rzp;
  WebViewController? _web;
  String? _error;
  bool _opened = false;
  bool _busy = false;

  bool get _native => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  String get _contact {
    final digits = widget.contact.replaceAll(RegExp(r'\D'), '');
    final ten = digits.length >= 10 ? digits.substring(digits.length - 10) : digits;
    return ten.length == 10 ? '+91$ten' : widget.contact;
  }

  String get _email {
    final e = widget.email.trim();
    if (e.contains('@')) return e;
    final digits = widget.contact.replaceAll(RegExp(r'\D'), '');
    final ten = digits.length >= 10 ? digits.substring(digits.length - 10) : 'rider';
    return 'rider$ten@evuddy.com';
  }

  /// Razorpay Continue only proceeds when contact + email + method are set.
  Map<String, dynamic> get _options {
    return {
      'key': widget.order.keyId,
      'amount': widget.order.amountPaise(widget.rupees),
      'currency': widget.order.currency.isEmpty ? 'INR' : widget.order.currency,
      'name': widget.order.name.isEmpty ? 'EVUDDY' : widget.order.name,
      'description': 'EVUDDY booking ${widget.bookingId}',
      'order_id': widget.order.orderId,
      'timeout': 300,
      'send_sms_hash': true,
      'remember_customer': false,
      'retry': {'enabled': true, 'max_count': 1},
      'prefill': {
        'name': widget.customerName.isEmpty ? 'Rider' : widget.customerName,
        'email': _email,
        'contact': _contact,
        'method': 'card',
      },
      'theme': {'color': '#16A34A'},
      'notes': {
        'bookingId': widget.bookingId,
        if (widget.vehicleId != null && widget.vehicleId!.isNotEmpty)
          'vehicleId': widget.vehicleId,
      },
    };
  }

  @override
  void initState() {
    super.initState();
    if (_native) {
      final rzp = Razorpay();
      rzp.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onNativeSuccess);
      rzp.on(Razorpay.EVENT_PAYMENT_ERROR, _onNativeError);
      rzp.on(Razorpay.EVENT_EXTERNAL_WALLET, _onWallet);
      _rzp = rzp;
      WidgetsBinding.instance.addPostFrameCallback((_) => _openNative());
    } else {
      _initWeb();
    }
  }

  void _onNativeSuccess(PaymentSuccessResponse res) {
    if (!mounted) return;
    Navigator.pop(context, {
      'orderId': res.orderId ?? widget.order.orderId,
      'paymentId': res.paymentId ?? '',
      'signature': res.signature ?? '',
    });
  }

  void _onNativeError(PaymentFailureResponse res) {
    if (!mounted) return;
    setState(() {
      _busy = false;
      _opened = false;
      _error = res.message ?? 'Payment was cancelled or failed.';
    });
  }

  void _onWallet(ExternalWalletResponse res) {
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = 'Open ${res.walletName ?? "the wallet"} to finish this payment.';
    });
  }

  Future<void> _openNative() async {
    if (_busy) return;
    final key = widget.order.keyId;
    final orderId = widget.order.orderId;
    if (key.isEmpty || orderId.isEmpty) {
      setState(() => _error = 'Razorpay order is missing a key or order id. Retry from Book EV.');
      return;
    }
    setState(() {
      _opened = true;
      _busy = true;
      _error = null;
    });
    try {
      _rzp!.open(_options);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _opened = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _initWeb() async {
    final web = WebViewController();
    web.setJavaScriptMode(JavaScriptMode.unrestricted);
    web.setBackgroundColor(Evuddy.wash);
    web.setNavigationDelegate(
      NavigationDelegate(
        onNavigationRequest: (_) => NavigationDecision.navigate,
      ),
    );
    web.addJavaScriptChannel(
      'PayBridge',
      onMessageReceived: (m) {
          final raw = jsonDecode(m.message);
          if (raw is! Map) return;
          final type = raw['type']?.toString();
          if (type == 'ready') {
            _openWeb(web);
          } else if (type == 'success') {
            if (!mounted) return;
            Navigator.pop(context, {
              'orderId': raw['razorpay_order_id']?.toString() ?? '',
              'paymentId': raw['razorpay_payment_id']?.toString() ?? '',
              'signature': raw['razorpay_signature']?.toString() ?? '',
            });
          } else if (type == 'dismiss') {
            if (mounted) Navigator.pop(context);
          } else if (type == 'failed') {
            setState(() {
              _busy = false;
              _error = raw['message']?.toString() ?? 'Payment failed.';
            });
          }
      },
    );
    if (web.platform is AndroidWebViewController) {
      final android = web.platform as AndroidWebViewController;
      await android.setMixedContentMode(MixedContentMode.alwaysAllow);
      final cookies = WebViewCookieManager();
      final cookiePlatform = cookies.platform;
      if (cookiePlatform is AndroidWebViewCookieManager) {
        await cookiePlatform.setAcceptThirdPartyCookies(android, true);
      }
    }
    final html = await rootBundle.loadString('assets/pay/checkout.html');
    await web.loadHtmlString(html, baseUrl: EvuddyApi.origin);
    if (!mounted) return;
    setState(() => _web = web);
  }

  Future<void> _openWeb(WebViewController web) async {
    if (_opened) return;
    _opened = true;
    await web.runJavaScript('openPay(${jsonEncode(_options)})');
  }

  @override
  void dispose() {
    _rzp?.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Evuddy.wash,
      appBar: AppBar(
        backgroundColor: Evuddy.wash,
        foregroundColor: Evuddy.ink,
        elevation: 0,
        title: Text(
          'Pay securely',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const EvuddyLogo(height: 32),
            const SizedBox(height: 18),
            Text(
              CatalogRates.inr(widget.rupees),
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: Evuddy.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.bookingId.isEmpty ? 'Razorpay checkout' : 'Booking ${widget.bookingId}',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(color: Evuddy.muted, fontWeight: FontWeight.w600),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(color: Evuddy.danger, fontWeight: FontWeight.w600),
              ),
            ],
            const SizedBox(height: 22),
            if (_native) ...[
              FilledButton(
                onPressed: _busy
                    ? null
                    : () {
                        _opened = false;
                        _openNative();
                      },
                style: FilledButton.styleFrom(
                  backgroundColor: Evuddy.green,
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  _busy ? 'Opening Razorpay…' : 'Pay with Razorpay',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
                ),
              ),
              const Spacer(),
            ] else if (_web != null)
              Expanded(child: WebViewWidget(controller: _web!))
            else
              const Expanded(child: Center(child: CircularProgressIndicator())),
            Text(
              'Card, UPI, netbanking. Amount is verified on evuddy.com after success.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(color: Evuddy.muted, fontSize: 12, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
