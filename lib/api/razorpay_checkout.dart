import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    this.vehicleId,
  });

  final RazorpayOrder order;
  final String bookingId;
  final String contact;
  final String customerName;
  final String? vehicleId;

  @override
  State<RazorpayCheckoutPage> createState() => _RazorpayCheckoutPageState();
}

class _RazorpayCheckoutPageState extends State<RazorpayCheckoutPage> {
  late final WebViewController _web;
  bool _opened = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _web = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Evuddy.wash)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (_) => NavigationDecision.navigate,
        ),
      )
      ..addJavaScriptChannel(
        'PayBridge',
        onMessageReceived: (m) {
          final raw = jsonDecode(m.message);
          if (raw is! Map) return;
          final type = raw['type']?.toString();
          if (type == 'ready') {
            _open();
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
    _load();
  }

  Future<void> _load() async {
    final html = await rootBundle.loadString('assets/pay/checkout.html');
    await _web.loadHtmlString(html, baseUrl: EvuddyApi.origin);
  }

  Future<void> _open() async {
    if (_opened) return;
    _opened = true;
    final payload = jsonEncode({
      'key': widget.order.keyId,
      'amount': widget.order.amount,
      'currency': widget.order.currency,
      'name': widget.order.name,
      'image': widget.order.image,
      'description': 'Booking Payment - ${widget.bookingId}',
      'order_id': widget.order.orderId,
      'prefill': {
        'name': widget.customerName,
        'contact': widget.contact,
      },
      'notes': {
        'bookingId': widget.bookingId,
        if (widget.vehicleId != null) 'vehicleId': widget.vehicleId,
      },
    });
    await _web.runJavaScript('openPay(${jsonEncode(payload)})');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Evuddy.wash,
      appBar: AppBar(
        backgroundColor: Evuddy.wash,
        title: const Text('Razorpay'),
      ),
      body: Column(
        children: [
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(_error!, style: const TextStyle(color: Evuddy.danger)),
            ),
          Expanded(child: WebViewWidget(controller: _web)),
        ],
      ),
    );
  }
}
