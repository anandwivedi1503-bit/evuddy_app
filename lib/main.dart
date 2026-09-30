import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'api/evuddy_api.dart';
import 'api/firebase_phone.dart';
import 'shell.dart';
import 'state/registration_draft.dart';
import 'theme/evuddy.dart';

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

/// Yellow brand hold → white canvas with a pulsing wordmark → home.
class EvuddySplashScreen extends StatefulWidget {
  const EvuddySplashScreen({super.key});

  @override
  State<EvuddySplashScreen> createState() => _EvuddySplashScreenState();
}

class _EvuddySplashScreenState extends State<EvuddySplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _hold;
  late final AnimationController _toWhite;
  late final AnimationController _pulse;
  late final Animation<Color?> _bg;
  late final Animation<double> _logoScale;

  @override
  void initState() {
    super.initState();
    _hold = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _toWhite = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _bg = ColorTween(begin: Evuddy.rapidoYellow, end: Colors.white).animate(
      CurvedAnimation(parent: _toWhite, curve: Curves.easeInOutCubic),
    );
    _logoScale = Tween<double>(begin: 1, end: 1.08).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOutCubic),
    );
    EvuddyApi.health();
    registrationDraft.restore().then((_) {
      if (registrationDraft.phoneVerified) {
        registrationDraft.refreshFromServer();
      }
    });
    _run();
  }

  Future<void> _run() async {
    await _hold.forward();
    if (!mounted) return;
    _pulse.repeat(reverse: true);
    await _toWhite.forward();
    if (!mounted) return;
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    if (!mounted) return;
    _go();
  }

  void _go() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 420),
        pageBuilder: (_, __, ___) => const RiderShell(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _hold.dispose();
    _toWhite.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_toWhite, _pulse]),
      builder: (context, _) {
        final color = _bg.value ?? Evuddy.rapidoYellow;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            systemNavigationBarColor: color,
            systemNavigationBarIconBrightness: Brightness.dark,
          ),
          child: Scaffold(
            backgroundColor: color,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: ScaleTransition(
                  scale: _logoScale,
                  child: const EvuddySplashMark(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
