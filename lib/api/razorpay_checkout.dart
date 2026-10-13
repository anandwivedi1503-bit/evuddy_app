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
import '../widgets/chrome.dart';
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
  Razorpay? _sdk;
  WebViewController? _web;
  String? _error;
  bool _opened = false;
  bool _busy = true;
  bool _webMode = false;

  /// Native CheckoutActivity on Android emulators often dies with SSL -101.
  /// Website Book EV uses checkout.js in the page — we do the same in a WebView.
  bool get _startWithWeb => kIsWeb || Platform.isAndroid;

  String get _contact10 {
    final digits = widget.contact.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 10) return digits.substring(digits.length - 10);
    return digits;
  }

  Map<String, dynamic> get _options {
    final name = widget.order.name.trim().isEmpty ? 'EVUDDY' : widget.order.name.trim();
    return {
      'key': widget.order.keyId,
      'amount': widget.order.amountPaise(widget.rupees),
      'currency': widget.order.currency.isEmpty ? 'INR' : widget.order.currency,
      'name': name,
      'description': 'Booking Payment - ${widget.bookingId}',
      'order_id': widget.order.orderId,
      'prefill': {
        'name': widget.customerName.isEmpty ? 'Rider' : widget.customerName,
        'contact': _contact10,
        if (widget.email.contains('@')) 'email': widget.email,
      },
      'notes': {
        'bookingId': widget.bookingId,
        if (widget.vehicleId != null && widget.vehicleId!.isNotEmpty)
          'vehicleId': widget.vehicleId,
      },
      'theme': {'color': '#16A34A'},
      'retry': {'enabled': true, 'max_count': 2},
      'method': {
        'netbanking': true,
        'card': true,
        'upi': true,
        'wallet': false,
        'emi': false,
        'paylater': false,
      },
      'config': {
        'display': {
          'hide': [
            {'method': 'wallet'},
            {'method': 'paylater'},
            {'method': 'emi'},
          ],
        },
      },
    };
  }

  @override
  void initState() {
    super.initState();
    if (_startWithWeb) {
      _webMode = true;
      _initFlutterWeb();
    } else {
      _sdk = Razorpay();
      _sdk!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onSdkSuccess);
      _sdk!.on(Razorpay.EVENT_PAYMENT_ERROR, _onSdkError);
      _sdk!.on(Razorpay.EVENT_EXTERNAL_WALLET, _onSdkWallet);
      WidgetsBinding.instance.addPostFrameCallback((_) => _openSdk());
    }
  }

  @override
  void dispose() {
    _sdk?.clear();
    super.dispose();
  }

  void _succeed(String orderId, String paymentId, String signature) {
    if (!mounted) return;
    Navigator.pop(context, {
      'orderId': orderId.isEmpty ? widget.order.orderId : orderId,
      'paymentId': paymentId,
      'signature': signature,
    });
  }

  void _openSdk() {
    try {
      _sdk ??= Razorpay();
      _sdk!.open(Map<String, dynamic>.from(_options));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.toString();
      });
      _fallbackWeb();
    }
  }

  void _onSdkSuccess(PaymentSuccessResponse response) {
    _succeed(
      response.orderId ?? widget.order.orderId,
      response.paymentId ?? '',
      response.signature ?? '',
    );
  }

  bool _isSoftFail(String msg) {
    final t = msg.toLowerCase();
    return t.contains('cancel') ||
        t.contains('dismiss') ||
        t.contains('back pressed') ||
        t.contains('network') ||
        t.contains('ssl') ||
        t.contains('handshake') ||
        t.contains('reset') ||
        t.contains('timeout') ||
        t.contains('internet');
  }

  void _onSdkError(PaymentFailureResponse response) {
    if (!mounted) return;
    final msg = response.message ?? 'Payment failed.';
    setState(() {
      _busy = false;
      _error = _isSoftFail(msg)
          ? 'Razorpay closed before payment finished. Use UPI or card below — same checkout as evuddy.com.'
          : msg;
    });
    if (_isSoftFail(msg) && !_webMode) _fallbackWeb();
  }

  void _onSdkWallet(ExternalWalletResponse response) {
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error =
          'Use Razorpay UPI or card — same as evuddy.com. Wallet ${response.walletName ?? ""} is not enabled.';
    });
  }

  void _fallbackWeb() {
    if (_webMode) return;
    _webMode = true;
    _opened = false;
    _initFlutterWeb();
  }

  Future<void> _initFlutterWeb() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final web = WebViewController();
    web.setJavaScriptMode(JavaScriptMode.unrestricted);
    web.setBackgroundColor(const Color(0xFFF7F8F5));
    web.addJavaScriptChannel(
      'PayBridge',
      onMessageReceived: (m) {
        final raw = jsonDecode(m.message);
        if (raw is! Map) return;
        final type = raw['type']?.toString();
        if (type == 'ready' && !_opened) {
          _opened = true;
          web.runJavaScript('openPay(${jsonEncode(_options)})');
        } else if (type == 'success' && mounted) {
          _succeed(
            raw['razorpay_order_id']?.toString() ?? '',
            raw['razorpay_payment_id']?.toString() ?? '',
            raw['razorpay_signature']?.toString() ?? '',
          );
        } else if (type == 'dismiss' && mounted) {
          setState(() {
            _busy = false;
            _error =
                'Checkout closed. Nothing was charged. Tap Pay again to open Razorpay UPI / card.';
          });
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
    }
    final html = await rootBundle.loadString('assets/pay/checkout.html');
    await web.loadHtmlString(html, baseUrl: EvuddyApi.origin);
    if (!mounted) return;
    setState(() {
      _web = web;
      _busy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Evuddy.wash,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Evuddy.ink,
        elevation: 0,
        title: const EvuddyLogo(height: 32),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PAY WITH RAZORPAY', style: Theme.of(context).textTheme.labelSmall),
                  const SizedBox(height: 6),
                  Text(
                    CatalogRates.inr(widget.rupees),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: Evuddy.greenDeep,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.bookingId} · UPI / card · Shubhrax Mobility Limited',
                    style: GoogleFonts.plusJakartaSans(
                      color: Evuddy.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Column(
                children: [
                  InfoNote(text: _error!),
                  const SizedBox(height: 10),
                  EvuddyButton(
                    label: 'Pay again with Razorpay',
                    onPressed: () {
                      setState(() {
                        _error = null;
                        _busy = true;
                        _opened = false;
                      });
                      if (_webMode) {
                        _initFlutterWeb();
                      } else {
                        _openSdk();
                      }
                    },
                  ),
                ],
              ),
            ),
          Expanded(
            child: _webMode
                ? (_web == null
                    ? const Center(child: CircularProgressIndicator(color: Evuddy.green))
                    : WebViewWidget(controller: _web!))
                : Center(
                    child: _busy
                        ? const CircularProgressIndicator(color: Evuddy.green)
                        : Text(
                            'Complete payment in the Razorpay sheet.',
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}
