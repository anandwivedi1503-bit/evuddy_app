import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:webview_flutter/webview_flutter.dart';

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

  bool get _plugin => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  String get _contact10 {
    final digits = widget.contact.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 10) return digits.substring(digits.length - 10);
    return digits;
  }

  String get _email {
    final e = widget.email.trim();
    if (e.contains('@')) return e;
    return 'rider$_contact10@evuddy.com';
  }

  Map<String, dynamic> get _options {
    final image = widget.order.image;
    return {
      'key': widget.order.keyId,
      'amount': widget.order.amountPaise(widget.rupees),
      'currency': widget.order.currency.isEmpty ? 'INR' : widget.order.currency,
      'name': widget.order.name.isEmpty ? 'EVUDDY' : widget.order.name,
      'description': 'Booking Payment - ${widget.bookingId}',
      'order_id': widget.order.orderId,
      'send_sms_hash': true,
      'one_click_checkout': false,
      'prefill': {
        'name': widget.customerName.isEmpty ? 'Rider' : widget.customerName,
        'email': _email,
        'contact': '+91$_contact10',
        'method': 'upi',
      },
      'method': {
        'netbanking': '0',
        'card': '0',
        'upi': '1',
        'wallet': '0',
        'emi': '0',
        'paylater': '0',
      },
      'upi': {'flow': 'qr'},
      'notes': {
        'bookingId': widget.bookingId,
        if (widget.vehicleId != null && widget.vehicleId!.isNotEmpty)
          'vehicleId': widget.vehicleId,
      },
      'theme': {'color': '#18B368'},
      'config': {
        'display': {
          'blocks': {
            'upi_only': {
              'name': 'UPI / QR',
              'instruments': [
                {
                  'method': 'upi',
                  'flows': ['qr', 'intent', 'collect'],
                }
              ],
            },
          },
          'hide': [
            {'method': 'card'},
            {'method': 'netbanking'},
            {'method': 'wallet'},
            {'method': 'emi'},
            {'method': 'paylater'},
          ],
          'sequence': ['block.upi_only'],
          'preferences': {'show_default_blocks': false},
        },
      },
      if (image != null && image.isNotEmpty) 'image': image,
    };
  }

  @override
  void initState() {
    super.initState();
    if (_plugin) {
      final rzp = Razorpay();
      rzp.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onOk);
      rzp.on(Razorpay.EVENT_PAYMENT_ERROR, _onErr);
      rzp.on(Razorpay.EVENT_EXTERNAL_WALLET, (_) {});
      _rzp = rzp;
      WidgetsBinding.instance.addPostFrameCallback((_) => _openPlugin());
    } else {
      _initWeb();
    }
  }

  void _onOk(PaymentSuccessResponse res) {
    if (!mounted) return;
    Navigator.pop(context, {
      'orderId': res.orderId ?? widget.order.orderId,
      'paymentId': res.paymentId ?? '',
      'signature': res.signature ?? '',
    });
  }

  void _onErr(PaymentFailureResponse res) {
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = res.message ?? 'Payment was cancelled or failed.';
    });
  }

  void _openPlugin() {
    final key = widget.order.keyId;
    final orderId = widget.order.orderId;
    if (key.isEmpty || orderId.isEmpty) {
      setState(() => _error = 'Razorpay order is missing a key or order id.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      _rzp!.open(_options);
    } catch (e) {
      setState(() {
        _busy = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _initWeb() async {
    final web = WebViewController();
    web.setJavaScriptMode(JavaScriptMode.unrestricted);
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
          Navigator.pop(context, {
            'orderId': raw['razorpay_order_id']?.toString() ?? '',
            'paymentId': raw['razorpay_payment_id']?.toString() ?? '',
            'signature': raw['razorpay_signature']?.toString() ?? '',
          });
        } else if (type == 'dismiss' && mounted) {
          Navigator.pop(context);
        } else if (type == 'failed') {
          setState(() => _error = raw['message']?.toString() ?? 'Payment failed.');
        }
      },
    );
    final html = await rootBundle.loadString('assets/pay/checkout.html');
    await web.loadHtmlString(html, baseUrl: EvuddyApi.origin);
    if (!mounted) return;
    setState(() => _web = web);
  }

  @override
  void dispose() {
    _rzp?.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FFF9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF18B368),
        foregroundColor: Colors.white,
        title: Text(
          'Pay securely',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            if (_error != null) ...[
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  color: Evuddy.danger,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (_plugin)
              FilledButton(
                onPressed: _busy ? null : _openPlugin,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF18B368),
                  minimumSize: const Size.fromHeight(54),
                ),
                child: Text(
                  _busy ? 'Opening UPI / QR…' : 'Pay with UPI / QR',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
                ),
              )
            else if (_web != null)
              Expanded(child: WebViewWidget(controller: _web!))
            else
              const Expanded(child: Center(child: CircularProgressIndicator())),
          ],
        ),
      ),
    );
  }
}
