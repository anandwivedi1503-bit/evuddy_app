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
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Evuddy.night,
      systemNavigationBarIconBrightness: Brightness.light,
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
    with TickerProviderStateMixin {
  late final AnimationController _intro;
  late final AnimationController _drift;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  late final Animation<double> _rise;
  late final Animation<double> _bar;

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _drift = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..repeat(reverse: true);

    _fade = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0, 0.55, curve: Curves.easeOut),
    );
    _scale = Tween<double>(begin: 0.88, end: 1).animate(
      CurvedAnimation(
        parent: _intro,
        curve: const Interval(0, 0.7, curve: Curves.easeOutCubic),
      ),
    );
    _rise = Tween<double>(begin: 28, end: 0).animate(
      CurvedAnimation(
        parent: _intro,
        curve: const Interval(0, 0.7, curve: Curves.easeOutCubic),
      ),
    );
    _bar = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _intro,
        curve: const Interval(0.28, 1, curve: Curves.easeInOutCubic),
      ),
    );
    _intro.forward();
    Timer(const Duration(milliseconds: 2800), _go);
  }

  void _go() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(evuddyRoute(const LoginScreen()));
  }

  @override
  void dispose() {
    _intro.dispose();
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Evuddy.night,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Evuddy.night,
        body: AnimatedBuilder(
          animation: Listenable.merge([_intro, _drift]),
          builder: (context, _) {
            final drift = (_drift.value - 0.5) * 28;
            return Stack(
              children: [
                const MeshBackdrop(dark: true),
                Positioned(
                  top: -40 + drift,
                  left: -60,
                  child: const GlowOrb(
                    color: Evuddy.logoGreen,
                    size: 280,
                    opacity: 0.55,
                  ),
                ),
                Positioned(
                  bottom: -30 - drift,
                  right: -80,
                  child: const GlowOrb(
                    color: Evuddy.logoPink,
                    size: 300,
                    opacity: 0.42,
                  ),
                ),
                Positioned(
                  top: 220,
                  right: 40 + drift * 0.4,
                  child: GlowOrb(
                    color: Evuddy.logoGreen.withOpacity(0.9),
                    size: 120,
                    opacity: 0.35,
                  ),
                ),
                FadeTransition(
                  opacity: _fade,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(28, 16, 28, 32),
                      child: Column(
                        children: [
                          const Spacer(flex: 2),
                          Transform.translate(
                            offset: Offset(0, _rise.value),
                            child: Transform.scale(
                              scale: _scale.value,
                              child: Column(
                                children: [
                                  const EvuddyBoltMark(size: 72),
                                  const SizedBox(height: 28),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.fromLTRB(
                                      22,
                                      26,
                                      22,
                                      22,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(28),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Evuddy.logoGreen.withOpacity(
                                            0.22,
                                          ),
                                          blurRadius: 40,
                                          offset: const Offset(0, 18),
                                        ),
                                      ],
                                    ),
                                    child: const EvuddyLogo(height: 86),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                          Text(
                            'Smart electric mobility',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withOpacity(0.72),
                              letterSpacing: 0.2,
                            ),
                          ),
                          const Spacer(flex: 3),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: SizedBox(
                              height: 4,
                              child: Stack(
                                children: [
                                  Container(
                                    color: Colors.white.withOpacity(0.12),
                                  ),
                                  FractionallySizedBox(
                                    widthFactor: _bar.value,
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Evuddy.logoGreen,
                                            Evuddy.logoPink,
                                          ],
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
                              letterSpacing: 2.6,
                              fontWeight: FontWeight.w800,
                              color: Colors.white.withOpacity(0.55),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
