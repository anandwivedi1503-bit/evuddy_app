import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'login_screen.dart';
import 'theme/evuddy.dart';
import 'widgets/chrome.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Evuddy.wash,
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

class EvuddySplashScreen extends StatefulWidget {
  const EvuddySplashScreen({super.key});

  @override
  State<EvuddySplashScreen> createState() => _EvuddySplashScreenState();
}

class _EvuddySplashScreenState extends State<EvuddySplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  late final Animation<double> _bar;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _fade = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.92, end: 1).animate(
      CurvedAnimation(parent: _c, curve: Curves.easeOutCubic),
    );
    _bar = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _c,
        curve: const Interval(0.35, 1, curve: Curves.easeOutCubic),
      ),
    );
    _c.forward();
    Timer(const Duration(milliseconds: 2600), _go);
  }

  void _go() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(evuddyRoute(const LoginScreen()));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Evuddy.wash,
      body: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          return FadeTransition(
            opacity: _fade,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 20, 28, 36),
                child: Column(
                  children: [
                    const Spacer(flex: 2),
                    Transform.scale(
                      scale: _scale.value,
                      child: const EvuddyLogo(height: 78),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'Smart electric mobility',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Evuddy.muted,
                      ),
                    ),
                    const Spacer(flex: 3),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: SizedBox(
                        height: 3,
                        child: Stack(
                          children: [
                            Container(color: Evuddy.line),
                            FractionallySizedBox(
                              widthFactor: _bar.value,
                              child: Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Evuddy.logoGreen, Evuddy.logoPink],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'LUCKNOW  ·  KANPUR',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        letterSpacing: 2.2,
                        fontWeight: FontWeight.w700,
                        color: Evuddy.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
