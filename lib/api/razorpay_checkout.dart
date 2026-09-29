import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

import '../theme/evuddy.dart';
import 'evuddy_api.dart';

/// Razorpay checkout.js inside a WebView — same as evuddy.com.
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
  WebViewController? _web;
  String? _error;
  bool _opened = false;

  String get _contact10 {
    final digits = widget.contact.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 10) return digits.substring(digits.length - 10);
    return digits;
  }

  /// Same payload as evuddy.com Book EV `new Razorpay({...})`.
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

  @override
  void initState() {
    super.initState();
    _initWeb();
  }

  Future<void> _initWeb() async {
    final web = WebViewController();
    web.setJavaScriptMode(JavaScriptMode.unrestricted);
    web.setBackgroundColor(const Color(0xFFF6FFF9));
    web.setNavigationDelegate(
      NavigationDelegate(
        onNavigationRequest: (req) {
          final uri = Uri.tryParse(req.url);
          if (uri != null && _upiSchemes.contains(uri.scheme.toLowerCase())) {
            launchUrl(uri, mode: LaunchMode.externalApplication);
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
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
          setState(() => _error = raw['message']?.toString() ?? 'Payment failed.');
        }
      },
    );
    if (web.platform is AndroidWebViewController) {
      final android = web.platform as AndroidWebViewController;
      await android.setMixedContentMode(MixedContentMode.alwaysAllow);
      try {
        await android.setPaymentRequestEnabled(true);
      } catch (_) {}
      await android.setUseWideViewPort(true);
      await android.setGeolocationEnabled(true);
      android.setOnPlatformPermissionRequest((request) => request.grant());
      await android.setCustomWidgetCallbacks(
        onShowCustomWidget: (child, onHidden) {
          if (!mounted) return;
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => Scaffold(body: child),
            ),
          ).whenComplete(onHidden);
        },
        onHideCustomWidget: () {
          if (mounted && Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        },
      );
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

  Widget _webView() {
    final controller = _web!;
    if (controller.platform is AndroidWebViewController) {
      return WebViewWidget.fromPlatformCreationParams(
        params: AndroidWebViewWidgetCreationParams.fromPlatformWebViewWidgetCreationParams(
          PlatformWebViewWidgetCreationParams(controller: controller.platform),
          displayWithHybridComposition: true,
        ),
      );
    }
    return WebViewWidget(controller: controller);
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
            child: _web == null
                ? const Center(child: CircularProgressIndicator())
                : _webView(),
          ),
        ],
      ),
    );
  }
}
