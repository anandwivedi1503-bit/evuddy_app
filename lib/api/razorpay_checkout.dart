import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import '../theme/evuddy.dart';
import 'evuddy_api.dart';

/// Android: native WebView that allows Razorpay `window.open` (Continue → UPI QR).
/// Other platforms: checkout.js in a Flutter WebView (same options as evuddy.com).
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
  static const _channel = MethodChannel('evuddy/razorpay');

  WebViewController? _web;
  String? _error;
  bool _opened = false;
  bool _launching = false;

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
      'prefill': {
        'name': widget.customerName.isEmpty ? 'Rider' : widget.customerName,
        'email': _email,
        'contact': '+91$_contact10',
        'method': 'upi',
      },
      'notes': {
        'bookingId': widget.bookingId,
        if (widget.vehicleId != null && widget.vehicleId!.isNotEmpty)
          'vehicleId': widget.vehicleId,
      },
      'theme': {'color': '#18B368'},
      'config': {
        'display': {
          'blocks': {
            'upi_qr': {
              'name': 'UPI / QR',
              'instruments': [
                {
                  'method': 'upi',
                  'flows': ['qr', 'collect', 'intent'],
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
          'sequence': ['block.upi_qr'],
          'preferences': {'show_default_blocks': false},
        },
      },
      if (image != null && image.isNotEmpty) 'image': image,
    };
  }

  bool get _androidNative => !kIsWeb && Platform.isAndroid;

  @override
  void initState() {
    super.initState();
    if (_androidNative) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openAndroid());
    } else {
      _initFlutterWeb();
    }
  }

  Future<void> _openAndroid() async {
    if (_launching) return;
    _launching = true;
    try {
      final html = await rootBundle.loadString('assets/pay/checkout.html');
      final raw = await _channel.invokeMethod<String>('open', {
        'html': html,
        'options': jsonEncode(_options),
      });
      if (!mounted) return;
      if (raw == null || raw.isEmpty) {
        Navigator.pop(context);
        return;
      }
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        Navigator.pop(context);
        return;
      }
      final type = decoded['type']?.toString();
      if (type == 'success') {
        Navigator.pop(context, {
          'orderId': decoded['razorpay_order_id']?.toString() ?? '',
          'paymentId': decoded['razorpay_payment_id']?.toString() ?? '',
          'signature': decoded['razorpay_signature']?.toString() ?? '',
        });
      } else if (type == 'failed') {
        setState(() {
          _launching = false;
          _error = decoded['message']?.toString() ?? 'Payment failed.';
        });
      } else {
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _launching = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _initFlutterWeb() async {
    final web = WebViewController();
    web.setJavaScriptMode(JavaScriptMode.unrestricted);
    web.setBackgroundColor(const Color(0xFFF6FFF9));
    web.addJavaScriptChannel(
      'PayBridge',
      onMessageReceived: (m) {
        final raw = jsonDecode(m.message);
        if (raw is! Map) return;
        final type = raw['type']?.toString();
        if (type == 'ready' && !_opened) {
          _opened = true;
          web.runJavaScript('openPay(${jsonEncode(_options)})');
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
          setState(() => _error = raw['message']?.toString() ?? 'Payment failed.');
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
    setState(() => _web = web);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FFF9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF18B368),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Pay securely',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
      ),
      body: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        color: Evuddy.danger,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_androidNative)
                      FilledButton(
                        onPressed: () {
                          setState(() {
                            _error = null;
                            _launching = false;
                          });
                          _openAndroid();
                        },
                        child: const Text('Retry Razorpay'),
                      ),
                  ],
                ),
              ),
            )
          : _androidNative
              ? const Center(child: CircularProgressIndicator())
              : (_web == null
                  ? const Center(child: CircularProgressIndicator())
                  : WebViewWidget(controller: _web!)),
    );
  }
}
