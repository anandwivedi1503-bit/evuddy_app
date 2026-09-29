import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/evuddy.dart';
import 'evuddy_api.dart';

/// checkout.js like evuddy.com. Uses InAppWebView so Razorpay Continue can
/// `window.open` the UPI QR step (webview_flutter cannot).
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
  InAppWebViewController? _web;
  String? _error;
  bool _opened = false;
  String? _html;

  static final _settings = InAppWebViewSettings(
    javaScriptEnabled: true,
    javaScriptCanOpenWindowsAutomatically: true,
    supportMultipleWindows: true,
    domStorageEnabled: true,
    databaseEnabled: true,
    thirdPartyCookiesEnabled: true,
    mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
    useHybridComposition: true,
    allowsInlineMediaPlayback: true,
    mediaPlaybackRequiresUserGesture: false,
    useShouldOverrideUrlLoading: true,
  );

  static const _upiSchemes = {
    'upi',
    'phonepe',
    'paytmmp',
    'tez',
    'gpay',
    'credpay',
    'bhim',
    'ppe',
    'intent',
  };

  String get _contact10 {
    final digits = widget.contact.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 10) return digits.substring(digits.length - 10);
    return digits;
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
      'prefill': {
        'name': widget.customerName.isEmpty ? 'Rider' : widget.customerName,
        'contact': _contact10,
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
          'sequence': ['block.upi_qr'],
          'preferences': {'show_default_blocks': true},
        },
      },
      if (image != null && image.isNotEmpty) 'image': image,
    };
  }

  @override
  void initState() {
    super.initState();
    rootBundle.loadString('assets/pay/checkout.html').then((html) {
      if (mounted) setState(() => _html = html);
    });
  }

  void _onPayMessage(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return;
    final type = decoded['type']?.toString();
    if (type == 'ready') {
      _openPay();
    } else if (type == 'success') {
      if (!mounted) return;
      Navigator.pop(context, {
        'orderId': decoded['razorpay_order_id']?.toString() ?? '',
        'paymentId': decoded['razorpay_payment_id']?.toString() ?? '',
        'signature': decoded['razorpay_signature']?.toString() ?? '',
      });
    } else if (type == 'dismiss') {
      if (mounted) Navigator.pop(context);
    } else if (type == 'failed') {
      setState(() => _error = decoded['message']?.toString() ?? 'Payment failed.');
    }
  }

  Future<void> _openPay() async {
    if (_opened || _web == null) return;
    _opened = true;
    await _web!.evaluateJavascript(source: 'openPay(${jsonEncode(_options)})');
  }

  Future<NavigationActionPolicy> _handleUrl(Uri? uri) async {
    if (uri != null && _upiSchemes.contains(uri.scheme.toLowerCase())) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return NavigationActionPolicy.CANCEL;
    }
    return NavigationActionPolicy.ALLOW;
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
      body: Column(
        children: [
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  color: Evuddy.danger,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          Expanded(
            child: _html == null
                ? const Center(child: CircularProgressIndicator())
                : InAppWebView(
                    initialSettings: _settings,
                    onWebViewCreated: (controller) async {
                      _web = controller;
                      controller.addJavaScriptHandler(
                        handlerName: 'PayBridge',
                        callback: (args) {
                          if (args.isEmpty) return null;
                          _onPayMessage(args.first.toString());
                          return null;
                        },
                      );
                      await controller.loadData(
                        data: _html!,
                        baseUrl: WebUri(EvuddyApi.origin),
                        historyUrl: WebUri(EvuddyApi.origin),
                      );
                    },
                    shouldOverrideUrlLoading: (controller, action) =>
                        _handleUrl(action.request.url),
                    onCreateWindow: (controller, action) async {
                      if (!mounted) return false;
                      await Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => _RazorpayWindow(
                            windowId: action.windowId,
                            settings: _settings,
                            onUrl: _handleUrl,
                          ),
                        ),
                      );
                      return true;
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _RazorpayWindow extends StatelessWidget {
  const _RazorpayWindow({
    required this.windowId,
    required this.settings,
    required this.onUrl,
  });

  final int windowId;
  final InAppWebViewSettings settings;
  final Future<NavigationActionPolicy> Function(Uri?) onUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF18B368),
        foregroundColor: Colors.white,
        title: const Text('UPI / QR'),
      ),
      body: InAppWebView(
        windowId: windowId,
        initialSettings: settings,
        shouldOverrideUrlLoading: (controller, action) => onUrl(action.request.url),
        onCloseWindow: (controller) {
          if (Navigator.of(context).canPop()) Navigator.of(context).pop();
        },
      ),
    );
  }
}
