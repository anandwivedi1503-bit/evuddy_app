import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import '../theme/evuddy.dart';
import '../widgets/chrome.dart';
import 'evuddy_api.dart';

/// Official Razorpay Standard Checkout — same `checkout.js` as evuddy.com Book EV.
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
  bool _settled = false;

  bool get _androidHost =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  bool get _iosSdk =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  String get _contact10 {
    final digits = widget.contact.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 10) return digits.substring(digits.length - 10);
    return digits;
  }

  /// Same fields as kebuone-website Book EV `new window.Razorpay({...})`.
  Map<String, dynamic> get _options {
    final name =
        widget.order.name.trim().isEmpty ? 'EVUDDY' : widget.order.name.trim();
    final image = (widget.order.image ?? '').trim().isEmpty
        ? 'https://www.evuddy.com/Evuddy-logo-dark-E.png'
        : widget.order.image!.trim();
    return {
      'key': widget.order.keyId,
      'amount': widget.order.amountPaise(widget.rupees),
      'currency': widget.order.currency.isEmpty ? 'INR' : widget.order.currency,
      'name': name,
      'image': image,
      'description': 'Booking Payment - ${widget.bookingId}',
      if (widget.order.orderId.startsWith('order_'))
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
      'retry': {'enabled': true, 'max_count': 4},
    };
  }

  @override
  void initState() {
    super.initState();
    if (_androidHost || _iosSdk) {
      _sdk = Razorpay();
      _sdk!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onSdkSuccess);
      _sdk!.on(Razorpay.EVENT_PAYMENT_ERROR, _onSdkError);
      _sdk!.on(Razorpay.EVENT_EXTERNAL_WALLET, _onSdkWallet);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  @override
  void dispose() {
    _sdk?.clear();
    super.dispose();
  }

  Future<void> _start() async {
    if (!mounted || _settled) return;
    setState(() {
      _busy = true;
      _error = null;
      _web = null;
      _opened = false;
    });
    if (_androidHost || _iosSdk) {
      await Future<void>.delayed(const Duration(milliseconds: 80));
      if (!mounted || _settled) return;
      _openSdk();
      return;
    }
    await _initFlutterWeb();
  }

  Future<bool> _openAndroidCheckoutJs() async {
    final bundle = DefaultAssetBundle.of(context);
    try {
      final html = await bundle.loadString('assets/pay/checkout.html');
      final raw = await _channel.invokeMethod<String>('open', {
        'html': html,
        'options': jsonEncode(_options),
      });
      if (!mounted) return true;
      return _handleBridgePayload(raw);
    } on PlatformException catch (e) {
      if (!mounted) return false;
      setState(() {
        _busy = false;
        _error = e.message ?? 'Could not open Razorpay checkout.';
      });
      return false;
    } catch (e) {
      if (!mounted) return false;
      setState(() {
        _busy = false;
        _error = e.toString();
      });
      return false;
    }
  }

  bool _handleBridgePayload(String? raw) {
    Map<String, dynamic> data = const {};
    if (raw != null && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          data = decoded.map((k, v) => MapEntry(k.toString(), v));
        }
      } catch (_) {}
    }
    final type = data['type']?.toString() ?? 'dismiss';
    if (type == 'success') {
      _succeed(
        data['razorpay_order_id']?.toString() ?? '',
        data['razorpay_payment_id']?.toString() ?? '',
        data['razorpay_signature']?.toString() ?? '',
      );
      return true;
    }
    setState(() {
      _busy = false;
      _error = type == 'failed'
          ? (data['message']?.toString() ?? 'Payment failed. Please try again.')
          : 'Payment cancelled. You can try again.';
    });
    return true;
  }

  void _succeed(String orderId, String paymentId, String signature) {
    if (!mounted || _settled) return;
    _settled = true;
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
    }
  }

  void _onSdkSuccess(PaymentSuccessResponse response) {
    _succeed(
      response.orderId ?? widget.order.orderId,
      response.paymentId ?? '',
      response.signature ?? '',
    );
  }

  void _onSdkError(PaymentFailureResponse response) {
    if (!mounted || _settled) return;
    final msg = (response.message ?? 'Payment failed.').toLowerCase();
    final cancelled = response.code == Razorpay.PAYMENT_CANCELLED ||
        msg.contains('cancel') ||
        msg.contains('dismiss') ||
        msg.contains('back pressed');
    setState(() {
      _busy = false;
      _error = cancelled
          ? 'Payment cancelled. You can try again.'
          : (response.message ?? 'Payment failed. Please try again.');
    });
  }

  void _onSdkWallet(ExternalWalletResponse response) {
    if (!mounted || _settled) return;
    setState(() {
      _busy = false;
      _error =
          'Finish the payment in ${response.walletName ?? 'the wallet app'}, then tap Pay securely with Razorpay again if this screen stays open.';
    });
  }

  Future<void> _openExternalPayUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  Future<void> _initFlutterWeb() async {
    final bundle = DefaultAssetBundle.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    final web = WebViewController();
    web.setJavaScriptMode(JavaScriptMode.unrestricted);
    web.setBackgroundColor(Colors.white);
    web.setNavigationDelegate(
      NavigationDelegate(
        onNavigationRequest: (request) {
          final u = request.url.toLowerCase();
          if (u.startsWith('http://') ||
              u.startsWith('https://') ||
              u.startsWith('about:') ||
              u.startsWith('data:') ||
              u.startsWith('blob:')) {
            return NavigationDecision.navigate;
          }
          _openExternalPayUrl(request.url);
          return NavigationDecision.prevent;
        },
      ),
    );
    web.addJavaScriptChannel(
      'PayBridge',
      onMessageReceived: (m) {
        final raw = jsonDecode(m.message);
        if (raw is! Map) return;
        final type = raw['type']?.toString();
        if (type == 'ready' && !_opened) {
          _opened = true;
          web.runJavaScript('openPay(${jsonEncode(_options)})');
        } else if (type == 'open') {
          final url = raw['url']?.toString() ?? '';
          if (url.isNotEmpty) _openExternalPayUrl(url);
        } else if (type == 'success' && mounted) {
          _succeed(
            raw['razorpay_order_id']?.toString() ?? '',
            raw['razorpay_payment_id']?.toString() ?? '',
            raw['razorpay_signature']?.toString() ?? '',
          );
        } else if (type == 'dismiss' && mounted) {
          setState(() {
            _busy = false;
            _error = 'Payment cancelled. You can try again.';
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
    if (!mounted) return;
    final html = await bundle.loadString('assets/pay/checkout.html');
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
      backgroundColor: const Color(0xFFF7F4EA),
      appBar: AppBar(
        backgroundColor: Evuddy.rapidoYellow,
        foregroundColor: Evuddy.ink,
        elevation: 0,
        title: const EvuddyLogo(height: 32),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 22,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SECURE RAZORPAY',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      letterSpacing: 1.6,
                      fontWeight: FontWeight.w800,
                      color: Evuddy.muted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    CatalogRates.inr(widget.rupees),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: Evuddy.ink,
                      letterSpacing: -1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${widget.bookingId}  ·  UPI / card / netbanking  ·  same checkout as evuddy.com',
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
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
              child: Column(
                children: [
                  InfoNote(text: _error!),
                  const SizedBox(height: 12),
                  EvuddyButton(
                    sun: true,
                    label: 'Pay securely with Razorpay',
                    onPressed: _start,
                  ),
                  if (_androidHost) ...[
                    const SizedBox(height: 8),
                    EvuddyGhostButton(
                      label: 'Open full-screen Razorpay',
                      onPressed: () => _openAndroidCheckoutJs(),
                    ),
                  ],
                ],
              ),
            )
          else if (_androidHost)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
              child: EvuddyGhostButton(
                label: 'Open full-screen Razorpay',
                onPressed: () => _openAndroidCheckoutJs(),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
              child: InfoNote(
                text: _busy
                    ? 'Razorpay is opening. Choose UPI, card or netbanking — same as evuddy.com.'
                    : 'Complete UPI, card or netbanking in the Razorpay sheet. EVUDDY never sees your PIN or card number.',
              ),
            ),
          Expanded(
            child: _web == null
                ? Center(
                    child: _busy
                        ? const CircularProgressIndicator(color: Evuddy.ink)
                        : const SizedBox.shrink(),
                  )
                : WebViewWidget(controller: _web!),
          ),
        ],
      ),
    );
  }
}
