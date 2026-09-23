import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../theme/evuddy.dart';

/// Website-style Firebase phone OTP (Recaptcha in a WebView).
/// Avoids the Android SHA-1 block on native Play Integrity.
///
/// Recaptcha image challenges (select cars, buses, …) render in a large
/// overlay. They were clipped when this panel was 124px with CSS scale.
class WebOtpPanel extends StatefulWidget {
  const WebOtpPanel({super.key, required this.controller});
  final WebOtpController controller;

  @override
  State<WebOtpPanel> createState() => _WebOtpPanelState();
}

class WebOtpController {
  _WebOtpPanelState? _state;
  void Function(String code)? onAutofill;

  bool get ready => _state?.ready ?? false;

  Future<void> send(String phone10) {
    final s = _state;
    if (s == null) {
      return Future.error('OTP security check is still loading.');
    }
    return s.send(phone10);
  }

  Future<({String uid, String token})> confirm(String code) {
    final s = _state;
    if (s == null) {
      return Future.error('OTP security check is still loading.');
    }
    return s.confirm(code);
  }
}

class _WebOtpPanelState extends State<WebOtpPanel> {
  late final WebViewController _web;
  Completer<void>? _sent;
  Completer<({String uid, String token})>? _verified;
  bool ready = false;
  String? lastError;

  @override
  void initState() {
    super.initState();
    widget.controller._state = this;
    _web = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Evuddy.wash)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (_) => NavigationDecision.navigate,
        ),
      )
      ..addJavaScriptChannel(
        'OtpBridge',
        onMessageReceived: (m) {
          final raw = jsonDecode(m.message);
          if (raw is! Map) return;
          final type = raw['type']?.toString();
          if (type == 'ready' || type == 'captcha') {
            setState(() => ready = true);
          } else if (type == 'sent') {
            _sent?.complete();
            _sent = null;
          } else if (type == 'verified') {
            _verified?.complete((
              uid: raw['uid']?.toString() ?? '',
              token: raw['token']?.toString() ?? '',
            ));
            _verified = null;
          } else if (type == 'sms') {
            final code = raw['code']?.toString().replaceAll(RegExp(r'\D'), '') ?? '';
            if (code.length >= 6) {
              widget.controller.onAutofill?.call(code.substring(0, 6));
            }
          } else if (type == 'error') {
            final msg = raw['message']?.toString() ?? 'OTP failed.';
            setState(() => lastError = msg);
            if (_sent != null && !_sent!.isCompleted) {
              _sent!.completeError(msg);
              _sent = null;
            }
            if (_verified != null && !_verified!.isCompleted) {
              _verified!.completeError(msg);
              _verified = null;
            }
          }
        },
      );
    _readyOnce = false;
  }

  bool _readyOnce = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_readyOnce) return;
    _readyOnce = true;
    _load();
  }

  Future<void> _load() async {
    final html = await DefaultAssetBundle.of(context).loadString('assets/otp/bridge.html');
    await _web.loadHtmlString(html, baseUrl: 'https://www.evuddy.com/');
  }

  Future<void> send(String phone10) async {
    for (var i = 0; i < 80 && !ready; i++) {
      await Future.delayed(const Duration(milliseconds: 150));
    }
    if (!ready) {
      return Future.error('Security check did not load. Check the network and retry.');
    }
    _sent = Completer<void>();
    await _web.runJavaScript("sendOtp('+91$phone10');");
    return _sent!.future.timeout(
      const Duration(seconds: 120),
      onTimeout: () => throw 'Timed out waiting for the security images. Complete “select all cars” then wait for SMS.',
    );
  }

  Future<({String uid, String token})> confirm(String code) {
    _verified = Completer<({String uid, String token})>();
    _web.runJavaScript("confirmOtp('$code');");
    return _verified!.future.timeout(const Duration(seconds: 30));
  }

  @override
  void dispose() {
    if (widget.controller._state == this) widget.controller._state = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Evuddy.paper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Evuddy.line),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.none,
        child: Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: [
            WebViewWidget(controller: _web),
            if (!ready)
              const Align(
                alignment: Alignment.topCenter,
                child: LinearProgressIndicator(minHeight: 2),
              ),
          ],
        ),
      ),
    );
  }
}
