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
import 'in_app_razorpay.dart';

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
    this.bookingMongoId = '',
    this.idToken = '',
  });

  final RazorpayOrder order;
  final String bookingId;
  final String contact;
  final String customerName;
  final double rupees;
  final String email;
  final String? vehicleId;
  final String bookingMongoId;
  final String idToken;

  @override
  State<RazorpayCheckoutPage> createState() => _RazorpayCheckoutPageState();
}

class _RazorpayCheckoutPageState extends State<RazorpayCheckoutPage>
    with WidgetsBindingObserver {
  static const _channel = MethodChannel('evuddy/razorpay');

  Razorpay? _sdk;
  WebViewController? _web;
  String? _error;
  bool _opened = false;
  bool _busy = true;
  bool _settled = false;
  bool _waitingChrome = false;

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
  /// Native CheckoutActivity rejects extra keys (token, rupees, bookingMongoId).
  Map<String, dynamic> get _nativeOptions => InAppRazorpay.optionsFor(
        order: widget.order,
        rupees: widget.rupees,
        bookingId: widget.bookingId,
        contact: widget.contact,
        customerName: widget.customerName,
        email: widget.email,
        vehicleId: widget.vehicleId,
      );

  Map<String, dynamic> get _options {
    return {
      ..._nativeOptions,
      'rupees': widget.rupees,
      if (widget.idToken.isNotEmpty) 'token': widget.idToken,
      if (widget.bookingMongoId.isNotEmpty) 'bookingMongoId': widget.bookingMongoId,
      if (widget.bookingId.isNotEmpty) 'bookingId': widget.bookingId,
    };
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
    WidgetsBinding.instance.removeObserver(this);
    _sdk?.clear();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _waitingChrome && !_settled) {
      _recoverAfterChrome();
    }
  }

  Map<String, dynamic> get _chromePayload {
    final native = _nativeOptions;
    return {
      ...native,
      if (widget.idToken.isNotEmpty) 'token': widget.idToken,
      if (widget.bookingMongoId.isNotEmpty) 'bookingMongoId': widget.bookingMongoId,
      if (widget.bookingId.isNotEmpty) 'bookingId': widget.bookingId,
    };
  }

  Future<void> _start() async {
    if (!mounted || _settled) return;
    setState(() {
      _busy = true;
      _error = null;
      _web = null;
      _opened = false;
      _waitingChrome = false;
    });
    final hasOrder = widget.order.orderId.startsWith('order_');
    final hasKey = widget.order.keyId.startsWith('rzp_');
    // Real Chrome (same as evuddy.com). In-app WebView is what shows Continue
    // and that button cannot open UPI QR / GPay.
    if (hasOrder && hasKey) {
      if (await _openChromeCheckout()) return;
    }
    if (hasOrder && hasKey && (_androidHost || _iosSdk)) {
      await Future<void>.delayed(const Duration(milliseconds: 80));
      if (!mounted || _settled) return;
      if (_openSdk()) return;
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error =
          'Could not open Razorpay in Chrome. Check internet and tap Pay securely with Razorpay again.';
    });
  }

  Future<bool> _openChromeCheckout() async {
    final uri = RazorpayWebHost.chromePayUri(_chromePayload);
    try {
      var ok = false;
      try {
        ok = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
      } catch (_) {
        ok = false;
      }
      if (!ok) {
        ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      if (!ok || !mounted) return ok;
      setState(() {
        _busy = false;
        _waitingChrome = true;
        _error = null;
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _recoverAfterChrome() async {
    if (!mounted || _settled || widget.bookingMongoId.isEmpty) return;
    try {
      final token = widget.idToken;
      if (token.isEmpty) return;
      final booking = await EvuddyApi.verifyPayment(
        idToken: token,
        bookingMongoId: widget.bookingMongoId,
        recover: true,
      );
      if (booking.receivedAmount >= widget.rupees - 0.009 ||
          booking.hasPickupOtp ||
          booking.due + 0.009 < widget.rupees) {
        if (!mounted || _settled) return;
        _settled = true;
        Navigator.pop(context, {'alreadyPaid': 'true'});
      }
    } catch (_) {}
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
    if (type == 'already_paid') {
      if (!mounted || _settled) return true;
      _settled = true;
      Navigator.pop(context, {'alreadyPaid': 'true'});
      return true;
    }
    if (type == 'wallet') {
      if (!mounted || _settled) return true;
      _settled = true;
      Navigator.pop(context, {'alreadyPaid': 'true', 'wallet': 'true'});
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

  bool _openSdk() {
    try {
      _sdk ??= Razorpay();
      _sdk!.open(Map<String, dynamic>.from(_nativeOptions));
      if (mounted) setState(() => _busy = false);
      return true;
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = e.toString();
        });
      }
      return false;
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
        } else if ((type == 'already_paid' || type == 'wallet') && mounted) {
          if (!_settled) {
            _settled = true;
            Navigator.pop(context, {'alreadyPaid': 'true'});
          }
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
      await android.setUserAgent(RazorpayWebHost.chromeDesktopUa);
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
                    label: 'Pay in Chrome — same as website',
                    onPressed: _start,
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
              child: Column(
                children: [
                  InfoNote(
                    text: _busy
                        ? 'Opening the same Razorpay checkout as evuddy.com in Chrome…'
                        : _waitingChrome
                            ? 'Finish UPI QR / GPay / PhonePe in Chrome, then return here. There is no Continue button on the website checkout.'
                            : 'Complete UPI, card or netbanking in Razorpay. EVUDDY never sees your PIN or card number.',
                  ),
                  if (_waitingChrome) ...[
                    const SizedBox(height: 12),
                    EvuddyButton(
                      sun: true,
                      label: 'I have paid',
                      onPressed: _recoverAfterChrome,
                    ),
                    const SizedBox(height: 8),
                    EvuddyGhostButton(
                      label: 'Open Razorpay in Chrome again',
                      onPressed: _start,
                    ),
                  ],
                ],
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
