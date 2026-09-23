import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

/// Website-style Firebase phone OTP (Recaptcha in a WebView).
/// Avoids the Android SHA-1 block on native Play Integrity.
///
/// Invisible Recaptcha + Chrome UA so Google’s overlay can fill this WebView.
/// Do not wrap this panel in ClipRRect or a short AuthScreen expanded slot.
class WebOtpPanel extends StatefulWidget {
  const WebOtpPanel({super.key, required this.controller});
  final WebOtpController controller;

  @override
  State<WebOtpPanel> createState() => _WebOtpPanelState();
}

class WebOtpController {
  _WebOtpPanelState? _state;
  void Function(String code)? onAutofill;
  VoidCallback? onCaptcha;
  VoidCallback? onReady;
  VoidCallback? onExpired;

  bool get ready => _state?.widgetReady ?? false;
  bool get captchaSolved => _state?.captchaSolved ?? false;

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
  static const _chromeUa =
      'Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.6778.135 Mobile Safari/537.36';

  late final WebViewController _web;
  Completer<void>? _sent;
  Completer<({String uid, String token})>? _verified;
  OverlayEntry? _customView;
  bool widgetReady = false;
  bool captchaSolved = false;
  String? lastError;
  bool _readyOnce = false;

  @override
  void initState() {
    super.initState();
    widget.controller._state = this;
    _web = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setUserAgent(_chromeUa)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (_) => NavigationDecision.navigate,
          onWebResourceError: (err) {
            if (!mounted) return;
            if (widgetReady) return;
            setState(() => lastError = err.description);
          },
        ),
      )
      ..addJavaScriptChannel(
        'OtpBridge',
        onMessageReceived: (m) {
          final raw = jsonDecode(m.message);
          if (raw is! Map) return;
          final type = raw['type']?.toString();
          if (type == 'ready') {
            setState(() => widgetReady = true);
            widget.controller.onReady?.call();
          } else if (type == 'captcha') {
            setState(() {
              captchaSolved = true;
              widgetReady = true;
            });
            widget.controller.onCaptcha?.call();
          } else if (type == 'expired') {
            setState(() => captchaSolved = false);
            widget.controller.onExpired?.call();
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
            setState(() {
              lastError = msg;
              captchaSolved = false;
            });
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
    _configureAndroid();
  }

  Future<void> _configureAndroid() async {
    final platform = _web.platform;
    if (platform is! AndroidWebViewController) return;
    await platform.setMixedContentMode(MixedContentMode.alwaysAllow);
    await platform.setGeolocationEnabled(true);
    await platform.setOnPlatformPermissionRequest((request) {
      request.grant();
    });
    await platform.setGeolocationPermissionsPromptCallbacks(
      onShowPrompt: (params) async {
        return const GeolocationPermissionsResponse(allow: true, retain: true);
      },
    );
    await platform.setCustomWidgetCallbacks(
      onShowCustomWidget: (view, onHidden) {
        _customView?.remove();
        _customView = OverlayEntry(
          builder: (ctx) => Positioned.fill(
            child: Material(
              color: Colors.white,
              child: SafeArea(
                child: Stack(
                  children: [
                    Positioned.fill(child: view),
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        color: Colors.black,
                        onPressed: () {
                          _hideCustomView();
                          onHidden();
                        },
                        icon: const Icon(Icons.close),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        Overlay.of(context, rootOverlay: true).insert(_customView!);
      },
      onHideCustomWidget: _hideCustomView,
    );
    final cookies = WebViewCookieManager();
    final cookiePlatform = cookies.platform;
    if (cookiePlatform is AndroidWebViewCookieManager) {
      await cookiePlatform.setAcceptThirdPartyCookies(platform, true);
    }
  }

  void _hideCustomView() {
    _customView?.remove();
    _customView = null;
  }

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
    for (var i = 0; i < 80 && !widgetReady; i++) {
      await Future.delayed(const Duration(milliseconds: 150));
    }
    if (!widgetReady) {
      return Future.error('Security check did not load. Check the network and retry.');
    }
    _sent = Completer<void>();
    await _web.runJavaScript("sendOtp('+91$phone10');");
    return _sent!.future.timeout(
      const Duration(seconds: 120),
      onTimeout: () =>
          throw 'Timed out waiting for SMS after the security check. Tap Resend.',
    );
  }

  Future<({String uid, String token})> confirm(String code) {
    _verified = Completer<({String uid, String token})>();
    _web.runJavaScript("confirmOtp('$code');");
    return _verified!.future.timeout(const Duration(seconds: 30));
  }

  @override
  void dispose() {
    _hideCustomView();
    if (widget.controller._state == this) widget.controller._state = null;
    super.dispose();
  }

  Widget _webView() {
    final gestures = <Factory<OneSequenceGestureRecognizer>>{
      Factory<EagerGestureRecognizer>(() => EagerGestureRecognizer()),
    };
    if (WebViewPlatform.instance is AndroidWebViewPlatform) {
      return WebViewWidget.fromPlatformCreationParams(
        params: AndroidWebViewWidgetCreationParams(
          controller: _web.platform,
          displayWithHybridComposition: true,
          gestureRecognizers: gestures,
        ),
      );
    }
    return WebViewWidget(controller: _web, gestureRecognizers: gestures);
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _webView(),
          if (!widgetReady)
            const Align(
              alignment: Alignment.topCenter,
              child: LinearProgressIndicator(minHeight: 2),
            ),
        ],
      ),
    );
  }
}
