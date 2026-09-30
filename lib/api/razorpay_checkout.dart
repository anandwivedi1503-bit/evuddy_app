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
  static const _channel = MethodChannel('evuddy/razorpay');
  Razorpay? _sdk;
  WebViewController? _web;
  String? _error;
  bool _opened = false;
  bool _busy = true;

  bool get _androidWeb => !kIsWeb && Platform.isAndroid;
  bool get _useSdk => !kIsWeb && Platform.isIOS;

  String get _contact10 {
    final digits = widget.contact.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 10) return digits.substring(digits.length - 10);
    return digits;
  }

  /// Same payload as evuddy.com `new window.Razorpay({...})`.
  Map<String, dynamic> get _options {
    final image = (widget.order.image != null && widget.order.image!.isNotEmpty)
        ? widget.order.image
        : '${EvuddyApi.origin}/Evuddy-logo-dark-E.png';
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
      'theme': {'color': '#18B368'},
      'image': image,
      'method': {
        'netbanking': '1',
        'card': '1',
        'upi': '1',
        'wallet': '0',
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
    if (_androidWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openAndroidWeb());
    } else if (_useSdk) {
      _sdk = Razorpay();
      _sdk!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onSdkSuccess);
      _sdk!.on(Razorpay.EVENT_PAYMENT_ERROR, _onSdkError);
      _sdk!.on(Razorpay.EVENT_EXTERNAL_WALLET, _onSdkWallet);
      WidgetsBinding.instance.addPostFrameCallback((_) => _openSdk());
    } else {
      _initFlutterWeb();
    }
  }

  @override
  void dispose() {
    _sdk?.clear();
    super.dispose();
  }

  Future<void> _openAndroidWeb() async {
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
        return;
      }
      if (type == 'dismiss') {
        Navigator.pop(context);
        return;
      }
      setState(() {
        _busy = false;
        _error = decoded['message']?.toString() ?? 'Payment failed.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.toString();
      });
    }
  }

  void _openSdk() {
    try {
      _sdk!.open(Map<String, dynamic>.from(_options));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.toString();
      });
    }
  }

  void _onSdkSuccess(PaymentSuccessResponse response) {
    if (!mounted) return;
    Navigator.pop(context, {
      'orderId': response.orderId ?? widget.order.orderId,
      'paymentId': response.paymentId ?? '',
      'signature': response.signature ?? '',
    });
  }

  void _onSdkError(PaymentFailureResponse response) {
    if (!mounted) return;
    final msg = response.message ?? 'Payment failed.';
    if (msg.toLowerCase().contains('cancel') ||
        msg.toLowerCase().contains('dismiss') ||
        msg.toLowerCase().contains('back pressed')) {
      Navigator.pop(context);
      return;
    }
    setState(() {
      _busy = false;
      _error = msg;
    });
  }

  void _onSdkWallet(ExternalWalletResponse response) {
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error =
          'Use Razorpay UPI or card — same as evuddy.com. Wallet ${response.walletName ?? ""} is not enabled.';
    });
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
        } else if (type == 'success' && mounted) {
          Navigator.pop(context, {
            'orderId': raw['razorpay_order_id']?.toString() ?? '',
            'paymentId': raw['razorpay_payment_id']?.toString() ?? '',
            'signature': raw['razorpay_signature']?.toString() ?? '',
          });
        } else if (type == 'dismiss' && mounted) {
          Navigator.pop(context);
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

  void _retry() {
    setState(() {
      _error = null;
      _busy = true;
      _opened = false;
    });
    if (_androidWeb) {
      _openAndroidWeb();
    } else if (_useSdk) {
      _openSdk();
    } else {
      _initFlutterWeb();
    }
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
                    FilledButton(
                      onPressed: _retry,
                      child: const Text('Retry Razorpay'),
                    ),
                  ],
                ),
              ),
            )
          : (_androidWeb || _useSdk)
              ? Center(
                  child: _busy
                      ? const CircularProgressIndicator()
                      : Text(
                          'Complete payment in the Razorpay sheet.',
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                        ),
                )
              : (_web == null
                  ? const Center(child: CircularProgressIndicator())
                  : WebViewWidget(controller: _web!)),
    );
  }
}
