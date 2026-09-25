import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'api/evuddy_api.dart';
import 'api/firebase_phone.dart';
import 'shell.dart';
import 'state/registration_draft.dart';
import 'theme/evuddy.dart';
import 'widgets/chrome.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EvuddyFirebase.ensure();
  await registrationDraft.restore();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Evuddy.rapidoYellow,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const EvuddyApp());
}

class EvuddyApp extends StatelessWidget {
  const EvuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EVUDDY',
      theme: Evuddy.theme(),
      home: const EvuddySplashScreen(),
    );
  }
}

/// Rapido-style open: one solid field, centred wordmark scale, hold, fade to home.
class EvuddySplashScreen extends StatefulWidget {
  const EvuddySplashScreen({super.key});

  @override
  State<EvuddySplashScreen> createState() => _EvuddySplashScreenState();
}

class _EvuddySplashScreenState extends State<EvuddySplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _in;
  late final AnimationController _out;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  late final Animation<double> _exit;

  @override
  void initState() {
    super.initState();
    _in = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _out = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _fade = CurvedAnimation(parent: _in, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.78, end: 1).animate(
      CurvedAnimation(parent: _in, curve: Curves.easeOutBack),
    );
    _exit = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _out, curve: Curves.easeIn),
    );
    _in.forward();
    EvuddyApi.health();
    registrationDraft.restore().then((_) {
      if (registrationDraft.phoneVerified) {
        registrationDraft.refreshFromServer();
      }
    });
    Future<void>.delayed(const Duration(milliseconds: 1650), _go);
  }

  Future<void> _go() async {
    if (!mounted) return;
    await _out.forward();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(evuddyRoute(const RiderShell()));
  }

  @override
  void dispose() {
    _in.dispose();
    _out.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Evuddy.rapidoYellow,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Evuddy.rapidoYellow,
        body: FadeTransition(
          opacity: _exit,
          child: FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const EvuddySplashMark(),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Evuddy.ink.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
